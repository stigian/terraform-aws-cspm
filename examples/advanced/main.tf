# Configure the AWS Provider for your management account
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Get current partition information (detects GovCloud vs Commercial)
data "aws_partition" "current" {}

# Load configuration from YAML files
module "config_data" {
  source = "../../modules/config-data"

  config_directory = "${path.module}/config"
  project          = var.project
  global_tags      = var.global_tags
}

# Import existing AWS Organization if one exists
import {
  for_each = var.aws_organization_id != null && var.aws_organization_id != "" ? { org = var.aws_organization_id } : {}
  to       = module.organizations.aws_organizations_organization.this
  id       = each.value
}

# Import existing accounts - GovCloud partition
import {
  for_each = data.aws_partition.current.partition == "aws-us-gov" ? module.config_data.aws_account_parameters : {}
  to       = module.organizations.aws_organizations_account.govcloud[each.key]
  id       = each.key
}

# Import existing accounts - Commercial partition
import {
  for_each = data.aws_partition.current.partition != "aws-us-gov" ? module.config_data.aws_account_parameters : {}
  to       = module.organizations.aws_organizations_account.commercial[each.key]
  id       = each.key
}

# Organizations Module - Account and OU management with YAML configuration
module "organizations" {
  source = "../../modules/organizations"

  # Configuration from YAML
  project     = module.config_data.project
  global_tags = module.config_data.global_tags

  # Organization settings
  aws_organization_id    = var.aws_organization_id
  aws_account_parameters = module.config_data.aws_account_parameters
  organizational_units   = module.config_data.organizational_units

  # Control Tower integration
  control_tower_enabled = true
}

# Control Tower Module - Landing zone deployment
module "controltower" {
  source     = "../../modules/controltower"
  depends_on = [module.organizations]

  # Configuration consistency
  project     = module.organizations.project
  global_tags = module.organizations.global_tags
  aws_region  = var.aws_region

  # Account IDs from organizations module
  management_account_id  = module.organizations.management_account_id
  log_archive_account_id = module.organizations.log_archive_account_id
  audit_account_id       = module.organizations.audit_account_id

  # Control Tower settings
  deploy_landing_zone = var.deploy_landing_zone
  self_managed_sso    = var.self_managed_sso
}

# SSO Module - IAM Identity Center configuration with YAML-driven groups
module "sso" {
  source     = "../../modules/sso"
  depends_on = [module.controltower]

  # Configuration consistency
  project     = module.organizations.project
  global_tags = module.organizations.global_tags

  # Account integration
  account_id_map       = module.organizations.account_id_map
  account_role_mapping = module.organizations.account_role_mapping

  # SSO Configuration - Uses compliance-standardized groups and permission sets
  enable_sso_management     = var.enable_sso_management
  auto_detect_control_tower = var.auto_detect_control_tower
  existing_admin_user_id    = var.existing_admin_user_id

  # Optional additional admin users
  initial_admin_users = var.initial_admin_users
}
