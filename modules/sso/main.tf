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

check "existing_admin_user_exists" {
  assert {
    condition     = var.existing_admin_user_id == null || length(data.aws_identitystore_user.existing_admin_user) > 0
    error_message = "Existing admin user ID '${var.existing_admin_user_id}' does not exist in Identity Store. Verify the user ID is correct and the user hasn't been deleted."
  }
}

# Load AWS Security Reference Architecture (SRA) Account Types from YAML
# These match accreditation requirements and cannot be changed
locals {
  sra_account_types = yamldecode(file("${path.module}/../../config/sra-account-types.yaml"))

  # Extract just the account type names for validation
  valid_account_types = keys(local.sra_account_types)
}

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

###############################################################################
# Entra ID Resources (Optional)
# https://learn.microsoft.com/en-us/entra/identity/saas-apps/aws-single-sign-on-tutorial
###############################################################################

data "azuread_client_config" "current" {
  count = var.enable_entra_integration ? 1 : 0
}

data "azuread_application_published_app_ids" "well_known" {
  count = var.enable_entra_integration ? 1 : 0
}

data "azuread_application_template" "aws_sso" {
  count        = var.enable_entra_integration ? 1 : 0
  display_name = "AWS IAM Identity Center (successor to AWS Single Sign-On)"
}

# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application
resource "azuread_application" "aws_sso" {
  count            = var.enable_entra_integration ? 1 : 0
  display_name     = "${var.project}-aws-sso"
  notes            = "AWS SSO for ${var.project} organization."
  template_id      = data.azuread_application_template.aws_sso[0].template_id
  sign_in_audience = "AzureADMyOrg"
  owners           = local.group_owners
  web {
    redirect_uris = var.redirect_uris
  }

  lifecycle {
    ignore_changes = [
      identifier_uris,
      app_role
    ]
  }
}

resource "azuread_application_identifier_uri" "aws_sso" {
  count          = var.enable_entra_integration ? 1 : 0
  application_id = azuread_application.aws_sso[0].id
  identifier_uri = var.identifier_uri
}

# https://learn.microsoft.com/en-us/graph/application-saml-sso-configure-api
# Assigning a Service Principal turns the application into an Enterprise Application
resource "azuread_service_principal" "aws_sso" {
  count                         = var.enable_entra_integration ? 1 : 0
  client_id                     = azuread_application.aws_sso[0].client_id
  use_existing                  = true
  preferred_single_sign_on_mode = "saml"
  app_role_assignment_required  = true
  login_url                     = var.login_url
  notification_email_addresses  = var.saml_notification_emails
  feature_tags {
    enterprise = true
    gallery    = false
  }
}

resource "azuread_service_principal" "msgraph" {
  count        = var.enable_entra_integration ? 1 : 0
  client_id    = data.azuread_application_published_app_ids.well_known[0].result.MicrosoftGraph
  use_existing = true
}

# https://learn.microsoft.com/en-us/graph/permissions-reference
# Note: automatically grants admin consent for the permissions
resource "azuread_app_role_assignment" "user_read_all" {
  count               = var.enable_entra_integration ? 1 : 0
  app_role_id         = azuread_service_principal.msgraph[0].app_role_ids["User.Read.All"]
  principal_object_id = azuread_service_principal.aws_sso[0].object_id
  resource_object_id  = azuread_service_principal.msgraph[0].object_id
}

# Create the SAML SSO token signing certificate only if the Azure AD environment is global.
# This is because the usgovernment API does not support this feature.
# https://learn.microsoft.com/en-us/graph/api/serviceprincipal-addtokensigningcertificate?view=graph-rest-1.0&tabs=http
resource "azuread_service_principal_token_signing_certificate" "aws_sso" {
  count                = var.enable_entra_integration && var.azuread_environment == "global" ? 1 : 0
  service_principal_id = azuread_service_principal.aws_sso[0].id
}

# Create a random UUID for each AWS account app role
resource "random_uuid" "this" {
  for_each = var.enable_entra_integration ? local.aws_sso_groups : {}
}

resource "azuread_application_app_role" "aws_sso" {
  for_each = var.enable_entra_integration ? local.aws_sso_groups : {}

  application_id = azuread_application.aws_sso[0].id
  role_id        = random_uuid.this[each.key].id

  allowed_member_types = ["User"] # Also works for groups
  description          = "${each.value.display_name} group in IAM Identity Center."
  display_name         = each.value.display_name
}

resource "azuread_app_role_assignment" "aws_sso" {
  for_each = var.enable_entra_integration ? local.aws_sso_groups : {}

  app_role_id         = azuread_application_app_role.aws_sso[each.key].role_id
  principal_object_id = azuread_group.aws_sso_groups[each.key].object_id
  resource_object_id  = azuread_service_principal.aws_sso[0].object_id
}


###############################################################################
# Groups / Personas
#
# References:
# - https://github.com/NMMES-CHE/nmmes-ztpilot-proj/issues/39#issuecomment-2383304468
###############################################################################

resource "azuread_group" "aws_sso_groups" {
  for_each         = var.enable_entra_integration ? local.aws_sso_groups : {}
  display_name     = each.value.display_name
  description      = each.value.description
  owners           = local.group_owners
  security_enabled = true
}

resource "azuread_group" "entra_security_groups" {
  for_each         = var.enable_entra_integration ? local.entra_security_groups : {}
  display_name     = each.value.display_name
  description      = each.value.description
  owners           = local.group_owners
  security_enabled = true
}

###############################################################################
# Future Work
###############################################################################

###############################################################################
# App Owners Group
# This block creates an App Owners group that will manage the Enterprise Applications.
# This ensures positive control over the administration of the applications.
# Requires Entra Premium P1 or P2 license, uncomment these blocks for production.
###############################################################################

# # Import one or more existing users to assign to the group
# data "azuread_user" "existing" {
#   mail = "lance@stigian.com"
# }

# # Create the App Owners group and add owners and members
# resource "azuread_group" "app_owners" {
#   display_name       = "App Owners"
#   security_enabled   = true
#   assignable_to_role = true # Requires Entra Premium P1 or P2
#   owners = [
#     data.azuread_client_config.current.object_id, # The identity running Terraform Apply
#     # data.azuread_user.existing.object_id
#   ]

#   members = [
#     # data.azuread_user.existing.object_id,
#     # more users...
#   ]
# }

# # Activate the Application Administrator Directory Role
# # https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference
# resource "azuread_directory_role" "app_admin" {
#   template_id = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" # Application Administrator
# }

# resource "azuread_directory_role_assignment" "app_owners_admin" {
#   role_id             = azuread_directory_role.app_admin.object_id
#   principal_object_id = azuread_group.app_owners.object_id
# }
