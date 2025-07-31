data "aws_organizations_organization" "this" {}

data "aws_partition" "current" {}

# Load AWS Security Reference Architecture (SRA) Account Types from YAML
# These match accreditation requirements and cannot be changed
locals {
  sra_account_types = yamldecode(file("${path.module}/../../config/sra-account-types.yaml"))

  # Extract just the account type names for validation
  valid_account_types = keys(local.sra_account_types)
}

# Process account parameters (no transformation needed since we use explicit ou/lifecycle)
locals {
  processed_accounts = var.aws_account_parameters

  # Add Project tag to global tags
  global_tags = merge(var.global_tags, {
    Project = var.project
  })
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
    local.global_tags,
    {
      Lifecycle = each.value.lifecycle
    },
  )
}

# AWS Organizations accounts for commercial AWS (normal lifecycle behavior)
resource "aws_organizations_account" "commercial" {
  for_each = data.aws_partition.current.partition != "aws-us-gov" ? local.processed_accounts : {}

  name      = each.value.name
  email     = each.value.email
  parent_id = each.value.ou != "Root" ? aws_organizations_organizational_unit.this[each.value.ou].id : data.aws_organizations_organization.this.roots[0].id

  tags = merge(
    local.global_tags,
    {
      Lifecycle = each.value.lifecycle
    },
    # Add AccountType tag if account_type is specified
    each.value.account_type != "" ? { AccountType = each.value.account_type } : {}
  )

  lifecycle {
    prevent_destroy = true # prevents accidental deletion
  }
}

# AWS Organizations accounts for GovCloud (ignore name changes)
resource "aws_organizations_account" "govcloud" {
  for_each = data.aws_partition.current.partition == "aws-us-gov" ? local.processed_accounts : {}

  name      = each.value.name
  email     = each.value.email
  parent_id = each.value.ou != "Root" ? aws_organizations_organizational_unit.this[each.value.ou].id : data.aws_organizations_organization.this.roots[0].id

  tags = merge(
    local.global_tags,
    {
      Lifecycle = each.value.lifecycle
    },
    # Add AccountType tag if account_type is specified
    each.value.account_type != "" ? { AccountType = each.value.account_type } : {}
  )

  lifecycle {
    ignore_changes  = [name] # can only be changed from commercial account
    prevent_destroy = true   # prevents accidental deletion
  }
}
