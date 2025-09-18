# import {
#   to = module.cspm.aws_organizations_organization.this
#   id = "o-1234567890"
# }

data "aws_partition" "current" {}

# Conditionally import the AWS Organization resource only if an organization ID is provided.
# If var.aws_organization_id is null or empty, the import block is skipped.
# Complete Multi-Account CSPM Deployment Example
# This example deploys a full DISA SCCA-compliant multi-account organization
# with all security services enabled.

# Data sources and imports
data "aws_partition" "current" {}

# Import existing organization and accounts
import {
  for_each = var.aws_organization_id != null && var.aws_organization_id != "" ? { org = var.aws_organization_id } : {}
  to       = module.organizations.aws_organizations_organization.this
  id       = each.value
}

# Import accounts based on AWS partition
import {
  for_each = data.aws_partition.current.partition != "aws-us-gov" ? local.organizations_account_parameters : {}
  to       = module.organizations.aws_organizations_account.commercial[each.key]
  id       = each.key
}

import {
  for_each = data.aws_partition.current.partition == "aws-us-gov" ? local.organizations_account_parameters : {}
  to       = module.organizations.aws_organizations_account.govcloud[each.key]
  id       = each.key
}

###############################################################################
# Foundation: Organizations
###############################################################################

module "organizations" {
  source = "git::https://github.com/stigian/terraform-aws-cspm//modules/organizations?ref=main"

  project                          = var.project
  global_tags                      = var.global_tags
  aws_organization_id              = var.aws_organization_id
  organizations_account_parameters = local.organizations_account_parameters
  all_accounts_all_parameters      = local.aws_account_parameters
  organizational_units             = local.organizations_managed_ous
  control_tower_enabled            = var.control_tower_enabled
}

###############################################################################
# Foundation: Control Tower
###############################################################################

module "controltower_admin" {
  source = "git::https://github.com/stigian/terraform-aws-cspm//modules/controltower?ref=main"

  providers = {
    aws.log_archive = aws.log_archive
    aws.audit       = aws.audit
  }

  management_account_id  = local.management_account_id
  log_archive_account_id = local.log_archive_account_id
  audit_account_id       = local.audit_account_id
  governed_regions       = var.governed_regions

  project             = var.project
  global_tags         = var.global_tags
  aws_region          = var.aws_region
  self_managed_sso    = true
  deploy_landing_zone = true

  depends_on = [module.organizations]
}

###############################################################################
# Identity: SSO
###############################################################################

module "sso" {
  source = "git::https://github.com/stigian/terraform-aws-cspm//modules/sso?ref=main"

  project               = var.project
  global_tags           = var.global_tags
  account_id_map        = local.account_id_map
  account_role_mapping  = local.account_role_mapping
  enable_sso_management = true
}

###############################################################################
# Security Services: GuardDuty
###############################################################################

module "guardduty" {
  source = "git::https://github.com/stigian/terraform-aws-cspm//modules/guardduty?ref=main"

  providers = {
    aws.audit = aws.audit
  }

  audit_account_id              = local.audit_account_id
  global_tags                   = var.global_tags
  enable_s3_protection          = var.enable_s3_protection
  enable_runtime_monitoring     = var.enable_runtime_monitoring
  enable_malware_protection_ec2 = var.enable_malware_protection_ec2
  enable_lambda_protection      = var.enable_lambda_protection
  enable_eks_protection         = var.enable_eks_protection
  enable_rds_protection         = var.enable_rds_protection
  enable_malware_protection_s3  = var.enable_malware_protection_s3

  depends_on = [module.controltower_admin]
}

###############################################################################
# Security Services: Detective
###############################################################################

module "detective" {
  source = "git::https://github.com/stigian/terraform-aws-cspm//modules/detective?ref=main"

  providers = {
    aws.audit = aws.audit
  }

  audit_account_id = local.audit_account_id
  global_tags      = var.global_tags

  depends_on = [module.guardduty]
}

###############################################################################
# Security Services: Inspector2
###############################################################################

module "inspector2" {
  source = "git::https://github.com/stigian/terraform-aws-cspm//modules/inspector2?ref=main"

  providers = {
    aws.audit      = aws.audit
    aws.management = aws.management
  }

  audit_account_id       = local.audit_account_id
  member_account_ids_map = local.non_audit_account_ids_map
  global_tags            = var.global_tags
}

###############################################################################
# Security Services: Config
###############################################################################

module "awsconfig_admin" {
  source = "git::https://github.com/stigian/terraform-aws-cspm//modules/awsconfig/admin?ref=main"

  providers = {
    aws.management = aws.management
    aws.audit      = aws.audit
  }

  audit_account_id = local.audit_account_id
  organization_id  = var.aws_organization_id
  global_tags      = var.global_tags
  aggregator_name  = "${var.project}-org-config-aggregator"

  depends_on = [module.controltower_admin]
}

module "awsconfig_members" {
  source   = "git::https://github.com/stigian/terraform-aws-cspm//modules/awsconfig/member?ref=main"
  for_each = local.non_mgmt_accounts_map

  providers = {
    aws.member = aws.ct_exec[each.key]
  }

  depends_on = [module.awsconfig_admin]
}

###############################################################################
# Security Services: Security Hub
###############################################################################

module "securityhub" {
  source = "git::https://github.com/stigian/terraform-aws-cspm//modules/securityhub?ref=main"

  providers = {
    aws.audit = aws.audit
  }

  audit_account_id             = local.audit_account_id
  management_account_id        = local.management_account_id
  global_tags                  = var.global_tags
  aggregator_linking_mode      = var.aggregator_linking_mode
  aggregator_specified_regions = var.aggregator_specified_regions

  depends_on = [module.guardduty]
}

# Import existing accounts into the module if they are defined in the variables.
# Import to commercial resources when NOT in GovCloud
import {
  for_each = data.aws_partition.current.partition != "aws-us-gov" ? local.aws_account_parameters : {}
  to       = module.organizations.aws_organizations_account.commercial[each.key]
  id       = each.key
}

# Import to GovCloud resources when IN GovCloud

# Only import accounts that Organizations module will manage
import {
  for_each = data.aws_partition.current.partition == "aws-us-gov" ? local.organizations_account_parameters : {}
  to       = module.organizations.aws_organizations_account.govcloud[each.key]
  id       = each.key
}

module "organizations" {
  source = "../modules/organizations"

  project                          = var.project
  global_tags                      = var.global_tags
  aws_organization_id              = var.aws_organization_id
  organizations_account_parameters = local.organizations_account_parameters
  all_accounts_all_parameters      = local.aws_account_parameters
  organizational_units             = local.organizations_managed_ous
  control_tower_enabled            = var.control_tower_enabled
}

module "controltower_admin" { # change to controltower_admin
  source = "../modules/controltower"

  depends_on = [module.organizations]

  providers = {
    aws.log_archive = aws.log_archive
    aws.audit       = aws.audit
  }

  management_account_id  = local.management_account_id
  log_archive_account_id = local.log_archive_account_id
  audit_account_id       = local.audit_account_id

  project             = var.project
  global_tags         = var.global_tags
  aws_region          = var.aws_region
  self_managed_sso    = true # This sets accessManagement.enabled = false
  deploy_landing_zone = true
}

# Adds AWSControlTowerExecution role to non-LZ accounts
# TODO: remove this module, based on testing the above controltower_admin module is sufficient
module "controltower_members" {
  source = "../modules/controltower/member"

  depends_on = [module.controltower_admin]
  for_each   = local.non_lz_accounts

  providers = {
    aws.member = aws.org_exec[each.key]
  }

  member_account_id     = each.key
  management_account_id = local.management_account_id
  global_tags           = local.global_tags
}

module "sso" {
  source = "../modules/sso"

  project                   = var.project
  global_tags               = var.global_tags
  account_id_map            = local.account_id_map
  account_role_mapping      = local.account_role_mapping
  enable_sso_management     = true
  auto_detect_control_tower = true
  # existing_admin_user_id    = "8891c238-90a1-70e8-bf6c-0438721ecc9d" # UPDATE THIS with your actual User ID!

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

module "guardduty" {
  source = "../modules/guardduty"
  providers = {
    aws.audit = aws.audit
  }

  audit_account_id              = local.audit_account_id
  global_tags                   = var.global_tags
  enable_s3_protection          = var.enable_s3_protection
  enable_runtime_monitoring     = var.enable_runtime_monitoring
  enable_malware_protection_ec2 = var.enable_malware_protection_ec2
  enable_lambda_protection      = var.enable_lambda_protection
  enable_eks_protection         = var.enable_eks_protection
  enable_rds_protection         = var.enable_rds_protection
  enable_malware_protection_s3  = var.enable_malware_protection_s3
  malware_protection_s3_buckets = var.malware_protection_s3_buckets

  depends_on = [module.controltower_admin] # Wait for CT baseline
}

module "detective" {
  source = "../modules/detective"

  audit_account_id = local.audit_account_id
  global_tags      = var.global_tags

  providers = {
    aws.audit = aws.audit
  }

  depends_on = [module.guardduty]
}

module "inspector2" {
  source = "../modules/inspector2"

  audit_account_id       = local.audit_account_id
  member_account_ids_map = local.non_audit_account_ids_map
  global_tags            = var.global_tags

  providers = {
    aws.audit      = aws.audit
    aws.management = aws.management
  }
}

###############################################################################
# AWS Config
#   Module calls are split by admin, member, and conformance_pack due to
#   different scoping needs caused by Control Tower guardrails
#   module.awsconfig_conformance can be removed whenever this bug is fixed:
#     - https://github.com/hashicorp/terraform-provider-aws/issues/24545
###############################################################################
module "awsconfig_admin" {
  source = "../modules/awsconfig/admin"
  providers = {
    aws.management = aws.management
    aws.audit      = aws.audit
  }

  audit_account_id    = local.audit_account_id
  organization_id     = var.aws_organization_id
  global_tags         = var.global_tags
  ct_logs_bucket_name = "" # TODO: finish mgmt account recording, see comments in module

  depends_on = [module.controltower_admin]
}

module "awsconfig_members" {
  source   = "../modules/awsconfig/member"
  for_each = local.non_mgmt_accounts

  providers = {
    aws.member = aws.ct_exec[each.key]
  }

  depends_on = [module.controltower_members]
}

# module "awsconfig_management_account" {
#   source   = "../modules/awsconfig/member"

#   providers = {
#     aws.member = aws.management
#   }

#   depends_on = [module.control_tower_members]
# }


###############################################################################
# Security Hub
###############################################################################

module "securityhub" {
  source = "../modules/securityhub"

  audit_account_id      = local.audit_account_id
  management_account_id = local.management_account_id
  global_tags           = var.global_tags

  providers = {
    # aws.management = aws.management
    aws.audit = aws.audit
  }

  depends_on = [module.guardduty]
}