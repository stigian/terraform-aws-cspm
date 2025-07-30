

# import {
#   to = module.cspm.aws_organizations_organization.this
#   id = "o-1234567890"
# }

provider "aws" {
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"
}

data "aws_partition" "current" {}

# Load configuration from YAML files
module "yaml_transform" {
  source = "../modules/yaml-transform"

  config_directory  = "${path.module}/config"
  project           = var.project
  global_tags       = var.global_tags
  enable_validation = true
}

# Conditionally import the AWS Organization resource only if an organization ID is provided.
# If var.aws_organization_id is null or empty, the import block is skipped.
import {
  for_each = var.aws_organization_id != null && var.aws_organization_id != "" ? { org = var.aws_organization_id } : {}
  to       = module.organizations.aws_organizations_organization.this
  id       = each.value
}

# Import existing accounts into the module if they are defined in the variables.
# Import to commercial resources when NOT in GovCloud
import {
  for_each = data.aws_partition.current.partition != "aws-us-gov" ? module.yaml_transform.aws_account_parameters : {}
  to       = module.organizations.aws_organizations_account.commercial[each.key]
  id       = each.key
}

# Import to GovCloud resources when IN GovCloud
import {
  for_each = data.aws_partition.current.partition == "aws-us-gov" ? module.yaml_transform.aws_account_parameters : {}
  to       = module.organizations.aws_organizations_account.govcloud[each.key]
  id       = each.key
}

module "organizations" {
  source = "../modules/organizations"

  # Configuration from YAML transformation
  project                = module.yaml_transform.project
  global_tags            = module.yaml_transform.global_tags
  aws_organization_id    = var.aws_organization_id
  aws_account_parameters = module.yaml_transform.aws_account_parameters
  organizational_units   = module.yaml_transform.organizational_units
}

module "controltower" {
  source = "../modules/controltower"

  depends_on = [module.organizations]

  # Account IDs from yaml_transform module
  management_account_id  = module.yaml_transform.management_account_id
  log_archive_account_id = module.yaml_transform.log_archive_account_id
  audit_account_id       = module.yaml_transform.audit_account_id

  # Configuration consistency
  project     = module.yaml_transform.project
  global_tags = module.yaml_transform.global_tags
  aws_region  = var.aws_region

  # Control Tower settings
  self_managed_sso    = true # This sets accessManagement.enabled = false
  deploy_landing_zone = false
}

module "sso" {
  source = "../modules/sso"

  # Configuration consistency
  project     = module.yaml_transform.project
  global_tags = module.yaml_transform.global_tags

  # Account integration from yaml_transform module
  account_id_map       = module.yaml_transform.account_id_map
  account_role_mapping = module.yaml_transform.account_role_mapping

  # SSO Configuration
  enable_sso_management     = true
  auto_detect_control_tower = true

  # Day 1 Protection: Use existing SSO user for admin access
  existing_admin_user_id = "8891c238-90a1-70e8-bf6c-0438721ecc9d" # UPDATE THIS with your actual User ID!

  # Optional: Create additional admin users if needed
  # initial_admin_users = [
  #   {
  #     user_name    = "security.admin"
  #     display_name = "Security Administrator"
  #     email        = "security@your-company.com"
  #     given_name   = "Security"
  #     family_name  = "Administrator"
  #     admin_level  = "security"
  #   }
  # ]

  # Entra ID Integration (Optional)
  # enable_entra_integration     = var.enable_entra_integration
  # azuread_environment          = var.azuread_environment
  # entra_tenant_id              = var.entra_tenant_id
  # saml_notification_emails     = var.saml_notification_emails
  # login_url                    = var.login_url
  # redirect_uris                = var.redirect_uris
  # identifier_uri               = var.identifier_uri
  # entra_group_admin_object_ids = var.entra_group_admin_object_ids
}



# central_bucket_name_prefix = var.central_bucket_name_prefix
# account_id_map             = var.account_id_map
