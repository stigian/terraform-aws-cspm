# YAML-Based Configuration Example
# This example demonstrates the new YAML-based configuration approach
# using the config-data module to load and process configuration files

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"
}

# Get current partition information
data "aws_partition" "current" {}

# Load configuration from YAML files
module "config_data" {
  source = "../../modules/config-data"

  config_directory = "${path.module}/config"
  project          = var.project
  global_tags      = var.global_tags
}

# Conditionally import the AWS Organization resource
import {
  for_each = var.aws_organization_id != null && var.aws_organization_id != "" ? { org = var.aws_organization_id } : {}
  to       = module.organizations.aws_organizations_organization.this
  id       = each.value
}

# Import existing accounts (GovCloud)
import {
  for_each = data.aws_partition.current.partition == "aws-us-gov" ? module.config_data.aws_account_parameters : {}
  to       = module.organizations.aws_organizations_account.govcloud[each.key]
  id       = each.key
}

# Import existing accounts (Commercial)
import {
  for_each = data.aws_partition.current.partition != "aws-us-gov" ? module.config_data.aws_account_parameters : {}
  to       = module.organizations.aws_organizations_account.commercial[each.key]
  id       = each.key
}

# Organizations Module - using processed configuration
module "organizations" {
  source = "../../modules/organizations"

  project                = module.config_data.project
  aws_organization_id    = var.aws_organization_id
  aws_account_parameters = module.config_data.aws_account_parameters
  organizational_units   = module.config_data.organizational_units
  global_tags            = module.config_data.global_tags
}

# Control Tower Module - clean integration
module "controltower" {
  source = "../../modules/controltower"

  depends_on = [module.organizations]

  # Account IDs from organizations module
  management_account_id  = module.organizations.management_account_id
  log_archive_account_id = module.organizations.log_archive_account_id
  audit_account_id       = module.organizations.audit_account_id

  # Configuration from config-data module
  project     = module.config_data.project
  global_tags = module.config_data.global_tags
  aws_region  = var.aws_region

  # Control Tower settings
  deploy_landing_zone = var.deploy_landing_zone
  self_managed_sso    = var.self_managed_sso
}

# SSO Module - using configuration from YAML
module "sso" {
  source = "../../modules/sso"

  project     = module.config_data.project
  global_tags = module.config_data.global_tags

  # Account integration
  account_id_map = module.organizations.account_id_map

  # Map account names to their roles for SSO group assignments
  # This could be enhanced to read from YAML in the future
  account_role_mapping = {
    "SCCA Root"             = "management"
    "nmmes-zt-test-transit" = "network"
    "nmmes-zt-test-logging" = "log_archive"
    "nmmes-zt-test-auth"    = "audit"
    "nmmes-zt-test-app"     = "workload"
  }

  # SSO Configuration
  enable_sso_management     = true
  auto_detect_control_tower = true

  # Optional: Entra ID Integration
  # enable_entra_integration     = var.enable_entra_integration
  # azuread_environment          = var.azuread_environment
  # entra_tenant_id              = var.entra_tenant_id
  # saml_notification_emails     = var.saml_notification_emails
  # login_url                    = var.login_url
  # redirect_uris                = var.redirect_uris
  # identifier_uri               = var.identifier_uri
  # entra_group_admin_object_ids = var.entra_group_admin_object_ids
}
