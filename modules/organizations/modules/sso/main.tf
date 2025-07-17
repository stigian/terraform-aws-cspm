data "aws_partition" "current" {}

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
  notes            = "AWS SSO for ${var.project} account ${var.account_id_map.hubandspoke}."
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
# IAM Identity Store
###############################################################################

# TODO: add conditional to join var.security_groups.default list with additional groups
#       the caller may provide.

data "aws_ssoadmin_instances" "this" {
  count = var.enable_sso_management ? 1 : 0
}

resource "aws_identitystore_group" "this" {
  for_each          = var.enable_sso_management ? local.aws_sso_groups : {}
  display_name      = each.value.display_name
  description       = each.value.description
  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = var.enable_sso_management ? { for idx, assignment in local.sso_group_assignments : "${assignment.account_id}-${assignment.group_name}" => assignment } : {}

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.group_name].arn

  principal_id   = aws_identitystore_group.this[each.value.group_name].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}

# Permission sets mapping to personas and compliant framework roles
resource "aws_ssoadmin_permission_set" "this" {
  for_each         = var.enable_sso_management ? local.aws_sso_groups : {}
  name             = each.value.display_name
  description      = each.value.description
  instance_arn     = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each           = local.aws_sso_groups
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = each.value.managed_policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
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
