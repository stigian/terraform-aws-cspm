# Attach AmazonDetectiveFullAccess to aws_admin permission set for Detective console/API access
resource "aws_ssoadmin_managed_policy_attachment" "detective_fullaccess" {
  for_each           = local.sso_management_enabled && contains(keys(local.aws_sso_groups), "aws_admin") ? { aws_admin = local.aws_sso_groups["aws_admin"] } : {}
  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonDetectiveFullAccess"
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

# Validate existing admin user exists in Identity Store (if provided)
data "aws_identitystore_user" "existing_admin_user" {
  count             = var.existing_admin_user_id != null ? 1 : 0
  identity_store_id = data.aws_ssoadmin_instances.this[0].identity_store_ids[0]
  user_id           = var.existing_admin_user_id
}

# check "existing_admin_user_exists" {
#   assert {
#     condition     = var.existing_admin_user_id == null || length(data.aws_identitystore_user.existing_admin_user) > 0
#     error_message = "Existing admin user ID '${var.existing_admin_user_id}' does not exist in Identity Store. Verify the user ID is correct and the user hasn't been deleted."
#   }
# }

###############################################################################
# Control Tower Detection
###############################################################################

# Detect if Control Tower is managing the organization
data "aws_organizations_organization" "current" {
  count = var.auto_detect_control_tower ? 1 : 0
}

# Check for Control Tower-managed service access principals
locals {
  # Control Tower adds this service access principal when it manages the organization
  control_tower_principals = var.auto_detect_control_tower ? [
    for principal in try(data.aws_organizations_organization.current[0].aws_service_access_principals, []) :
    principal if principal == "controltower.amazonaws.com"
  ] : []

  # Determine if Control Tower is managing the organization
  control_tower_detected = length(local.control_tower_principals) > 0

  # Final determination of SSO management:
  # With self-managed SSO (accessManagement.enabled = false in CT manifest),
  # Control Tower doesn't manage SSO resources, so we can always manage them
  # when enable_sso_management = true, regardless of Control Tower presence
  sso_management_enabled = var.enable_sso_management
}

###############################################################################
# IAM Identity Store
###############################################################################

# TODO: add conditional to join var.security_groups.default list with additional groups
#       the caller may provide.

data "aws_ssoadmin_instances" "this" {
  count = local.sso_management_enabled ? 1 : 0
}

resource "aws_identitystore_group" "this" {
  for_each          = local.sso_management_enabled ? local.aws_sso_groups : {}
  display_name      = each.value.display_name
  description       = each.value.description
  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]
}

# Create initial admin users in AWS IAM Identity Center (only for new users)
resource "aws_identitystore_user" "initial_admins" {
  for_each = local.sso_management_enabled ? {
    for user in local.all_admin_users : user.user_name => user
  } : {}

  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]

  display_name = each.value.display_name
  user_name    = each.value.user_name

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
  }
}

# Add admin users to appropriate groups (both existing and newly created users)
resource "aws_identitystore_group_membership" "initial_admin_memberships" {
  for_each = local.sso_management_enabled ? local.initial_admin_group_memberships : {}

  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]
  group_id          = aws_identitystore_group.this[each.value.group_name].group_id
  member_id         = try(each.value.is_existing_user, false) ? each.value.user_id : aws_identitystore_user.initial_admins[each.value.user_name].user_id
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.sso_management_enabled ? { for idx, assignment in local.sso_group_assignments : "${assignment.account_id}-${assignment.group_name}" => assignment } : {}

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.group_name].arn

  principal_id   = aws_identitystore_group.this[each.value.group_name].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}

# Permission sets mapping to personas and compliant framework roles
resource "aws_ssoadmin_permission_set" "this" {
  for_each         = local.sso_management_enabled ? local.aws_sso_groups : {}
  name             = each.value.display_name
  description      = each.value.description
  instance_arn     = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each           = local.sso_management_enabled ? local.aws_sso_groups : {}
  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  managed_policy_arn = each.value.managed_policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
}
