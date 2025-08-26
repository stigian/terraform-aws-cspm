# import {
#   to = module.cspm.aws_organizations_organization.this
#   id = "o-1234567890"
# }

data "aws_partition" "current" {}

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

module "controltower" {
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
module "control_tower_members" {
  source = "../modules/controltower/member"

  depends_on = [module.controltower]
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
  existing_admin_user_id    = "8891c238-90a1-70e8-bf6c-0438721ecc9d" # UPDATE THIS with your actual User ID!

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

  depends_on = [module.controltower] # Wait for CT baseline
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

  audit_account_id = local.audit_account_id
  organization_id  = var.aws_organization_id
  global_tags      = var.global_tags

  depends_on = [module.controltower]
}

module "awsconfig_members" {
  source   = "../modules/awsconfig/member"
  for_each = local.non_mgmt_accounts

  providers = {
    aws.member = aws.ct_exec[each.key]
  }

  depends_on = [module.control_tower_members]
}


###############################################################################
# Security Hub
###############################################################################

# module "security_hub_admin" {
#   source = "../modules/security_hub/admin"

#   audit_account_id = local.audit_account_id
#   global_tags      = var.global_tags

#   providers = {
#     aws.audit = aws.audit
#   }

#   depends_on = [module.guardduty]
# }