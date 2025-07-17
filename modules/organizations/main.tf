data "aws_organizations_organization" "this" { provider = aws.management }

# Detect AWS partition to determine if we're running in GovCloud
data "aws_partition" "current" { provider = aws.management }

resource "aws_organizations_organization" "this" {
  provider = aws.management

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
  provider = aws.management
  for_each = var.organizational_units

  name      = each.key
  parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = merge(
    var.global_tags,
    { Lifecycle = each.value.lifecycle },
  )
}

# AWS Organizations accounts for commercial AWS (normal lifecycle behavior)
resource "aws_organizations_account" "commercial" {
  provider = aws.management
  for_each = data.aws_partition.current.partition != "aws-us-gov" ? var.aws_account_parameters : {}

  name      = each.value.name
  email     = each.value.email
  parent_id = each.value.ou != "Root" ? aws_organizations_organizational_unit.this[each.value.ou].id : data.aws_organizations_organization.this.roots[0].id

  tags = merge(
    var.global_tags,
    { Lifecycle = each.value.lifecycle },
  )
}

# AWS Organizations accounts for GovCloud (ignore name changes)
resource "aws_organizations_account" "govcloud" {
  provider = aws.management
  for_each = data.aws_partition.current.partition == "aws-us-gov" ? var.aws_account_parameters : {}

  name      = each.value.name
  email     = each.value.email
  parent_id = each.value.ou != "Root" ? aws_organizations_organizational_unit.this[each.value.ou].id : data.aws_organizations_organization.this.roots[0].id

  tags = merge(
    var.global_tags,
    { Lifecycle = each.value.lifecycle },
  )

  # In AWS GovCloud, account names can only be changed from the paired commercial account
  lifecycle {
    ignore_changes = [name]
  }
}
