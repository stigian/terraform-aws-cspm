data "aws_partition" "current" {}
data "aws_organizations_organization" "this" {}

# Validate that all provided account IDs are actually members of this organization
# Can be disabled for synthetic testing by setting enable_runtime_validation = false
check "accounts_exist_in_organization" {
  assert {
    condition = var.enable_runtime_validation ? alltrue([
      for account_id in keys(var.organizations_account_parameters) :
      contains(data.aws_organizations_organization.this.accounts[*].id, account_id)
    ]) : true
    error_message = "Some account IDs provided are not members of organization ${data.aws_organizations_organization.this.id}. Check that accounts exist and are not in a different organization."
  }
}

resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "controltower.amazonaws.com",
    "detective.amazonaws.com",
    "guardduty.amazonaws.com",
    "inspector2.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "ram.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]
  feature_set = "ALL"
  enabled_policy_types = [
    "BACKUP_POLICY",
    "SERVICE_CONTROL_POLICY",
  ]
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name      = each.key
  parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = merge(
    var.global_tags,
    {
      Lifecycle = each.value.lifecycle
    },
  )
}

# If Control Tower is enabled, and the account is in the Sandbox or Security OU, place it in the root,
#   Control Tower will move it to the appropriate OU later, so we ignore changes to parent_id
# If Control Tower is not enabled, place it in the specified OU or root if OU is "Root"
resource "aws_organizations_account" "commercial" {
  for_each = data.aws_partition.current.partition != "aws-us-gov" ? var.all_accounts_all_parameters : {}

  name      = each.value.name
  email     = each.value.email
  parent_id = (var.control_tower_enabled && (each.value.ou == "Sandbox" || each.value.ou == "Security")) ? data.aws_organizations_organization.this.roots[0].id : (each.value.ou != "Root" ? aws_organizations_organizational_unit.this[each.value.ou].id : data.aws_organizations_organization.this.roots[0].id)

  tags = merge(
    var.global_tags,
    {
      Lifecycle = each.value.lifecycle
    },
    each.value.account_type != "" ? { AccountType = each.value.account_type } : {}
  )

  lifecycle {
    prevent_destroy = true # prevents accidental deletion
    ignore_changes = [ parent_id ] # prevent contention between Control Tower and Organizations module
  }
}

# If Control Tower is enabled, and the account is in the Sandbox or Security OU, place it in the root,
#   Control Tower will move it to the appropriate OU later, so we ignore changes to parent_id
# If Control Tower is not enabled, place it in the specified OU or root if OU is "Root"
resource "aws_organizations_account" "govcloud" {
  for_each = data.aws_partition.current.partition == "aws-us-gov" ? var.all_accounts_all_parameters : {}

  name      = each.value.name
  email     = each.value.email
  parent_id = (var.control_tower_enabled && (each.value.ou == "Sandbox" || each.value.ou == "Security")) ? data.aws_organizations_organization.this.roots[0].id : (each.value.ou != "Root" ? aws_organizations_organizational_unit.this[each.value.ou].id : data.aws_organizations_organization.this.roots[0].id)

  tags = merge(
    var.global_tags,
    {
      Lifecycle = each.value.lifecycle
    },
    each.value.account_type != "" ? { AccountType = each.value.account_type } : {}
  )

  lifecycle {
    prevent_destroy = true   # prevents accidental deletion
    ignore_changes  = [
      name, # can only be changed from commercial account
      parent_id, # prevent contention between Control Tower and Organizations module
    ]
  }
}
