# Organizations + SSO Integration Example

module "organizations" {
  source = "../../organizations"

  project             = var.project
  aws_organization_id = var.aws_organization_id

  organizational_units   = var.organizational_units
  aws_account_parameters = var.aws_account_parameters
}

module "sso" {
  source = "../"

  project        = var.project
  global_tags    = var.global_tags
  account_id_map = module.organizations.account_id_map

  # Map account names to their roles for SSO group assignments
  account_role_mapping = {
    "Management"  = "management"
    "Network"     = "network"
    "Log Archive" = "log_archive"
    "Audit"       = "audit"
  }

  # SSO Configuration
  enable_sso_management     = var.enable_sso_management
  auto_detect_control_tower = var.auto_detect_control_tower

  # Entra ID Integration (Optional)
  enable_entra_integration     = var.enable_entra_integration
  azuread_environment          = var.azuread_environment
  entra_tenant_id              = var.entra_tenant_id
  saml_notification_emails     = var.saml_notification_emails
  login_url                    = var.login_url
  redirect_uris                = var.redirect_uris
  identifier_uri               = var.identifier_uri
  entra_group_admin_object_ids = var.entra_group_admin_object_ids
}
