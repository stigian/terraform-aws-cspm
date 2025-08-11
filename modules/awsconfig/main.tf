# Optionally enable AWS Config auto-enable automation (submodule)
# module "autoenable" {
#   source        = "./autoenable"
#   count         = var.enable_autoenable ? 1 : 0
#   bucket_name   = var.autoenable_bucket_name
#   region        = var.autoenable_region
#   kms_user_arns = var.autoenable_kms_user_arns
#   providers = {
#     aws.audit = aws.audit
#   }
# }
###############################################################################
# AWS Config - Organization Delegation and Aggregation
#
# Phase 1 scope:
# - Delegate AWS Config admin to the Audit account (from Management)
# - Delegate Config Multi-Account Setup to the Audit account (from Management)
# - Create an organization-wide Configuration Aggregator in the Audit account
#
# Notes:
# - Do NOT manage recorders/delivery channels (Control Tower owned)
# - Conformance Pack is gated and optional (Phase 2)
###############################################################################

data "aws_partition" "current" {}

resource "aws_organizations_delegated_administrator" "config" {
  provider          = aws.management
  account_id        = var.audit_account_id
  service_principal = "config.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "config_multiaccountsetup" {
  provider          = aws.management
  account_id        = var.audit_account_id
  service_principal = "config-multiaccountsetup.amazonaws.com"
}

resource "aws_iam_role" "config_aggregator" {
  provider = aws.audit
  name     = "AWSConfigRoleForOrganizations-Aggregator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_aggregator_orgs" {
  provider   = aws.audit
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_aggregator" "org" {
  provider = aws.audit
  name     = var.aggregator_name

  organization_aggregation_source {
    role_arn    = aws_iam_role.config_aggregator.arn
    all_regions = var.aggregator_all_regions
  }

  depends_on = [
    aws_organizations_delegated_administrator.config,
    aws_organizations_delegated_administrator.config_multiaccountsetup,
    aws_iam_role_policy_attachment.config_aggregator_orgs,
  ]
}

resource "aws_config_organization_conformance_pack" "this" {
  count             = var.enable_conformance_pack ? 1 : 0
  provider          = aws.audit
  name              = var.conformance_pack_name
  template_body     = file("${path.module}/templates/${var.conformance_pack_template_path}")
  excluded_accounts = var.conformance_pack_excluded_accounts

  depends_on = [
    aws_config_configuration_aggregator.org,
  ]
}
