# Note: the destroy behavior for some of these resources does not actually
#       delete the resources or revert the configuration in the AWS account.
#       Read the documentation for each resource to understand the implications.

locals {
  management_account_id  = var.account_id_map["management"]
  hubandspoke_account_id = var.account_id_map["hubandspoke"]
  log_account_id         = var.account_id_map["log"]
  audit_account_id       = var.account_id_map["audit"]

  # https://docs.aws.amazon.com/controltower/latest/userguide/landing-zone-schemas.html#lz-3-3-schema
  landing_zone_manifest = templatefile("${path.module}/templates/LandingZoneManifest.tpl.json", {
    logging_account_id  = var.account_id_map["log"],
    security_account_id = var.account_id_map["audit"],
    kms_key_arn         = aws_kms_key.control_tower.arn
  })
}

data "aws_partition" "log" { provider = aws.log }
data "aws_partition" "audit" { provider = aws.audit }
data "aws_partition" "management" { provider = aws.management }
data "aws_partition" "hubandspoke" { provider = aws.hubandspoke }

data "aws_caller_identity" "log" { provider = aws.log }
data "aws_caller_identity" "audit" { provider = aws.audit }
data "aws_caller_identity" "management" { provider = aws.management }
data "aws_caller_identity" "hubandspoke" { provider = aws.hubandspoke }

data "aws_region" "audit" { provider = aws.audit }

data "aws_organizations_organization" "this" { provider = aws.management }

# Also enables Trusted Access in the management account.
resource "aws_organizations_organization" "this" {
  provider = aws.management
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "controltower.amazonaws.com",
    "detective.amazonaws.com",
    "guardduty.amazonaws.com",
    "inspector2.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "ram.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]
  feature_set = "ALL"
  enabled_policy_types = [
    # "BACKUP_POLICY",
    "SERVICE_CONTROL_POLICY",
  ]
}

###############################################################################
# Amazon GuardDuty (required before Detective)
#
# https://aws.github.io/aws-security-services-best-practices/guides/guardduty/
###############################################################################

# Side-effect: creates service-linked roles in all accounts
resource "aws_guardduty_organization_admin_account" "this" {
  provider         = aws.management         # from
  admin_account_id = local.audit_account_id # to
  depends_on       = [aws_organizations_organization.this]
}

resource "aws_guardduty_organization_configuration" "this" {
  #checkov:skip=CKV2_AWS_3:false positive
  provider                         = aws.audit
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.audit.id
  depends_on                       = [aws_guardduty_organization_admin_account.this]
}

resource "aws_guardduty_detector" "log" {
  #checkov:skip=CKV2_AWS_3:false positive
  provider = aws.log
  enable   = true
}

resource "aws_guardduty_detector" "audit" {
  #checkov:skip=CKV2_AWS_3:false positive
  provider = aws.audit
  enable   = true
}

resource "aws_guardduty_detector" "management" {
  #checkov:skip=CKV2_AWS_3:false positive
  provider = aws.management
  enable   = true
}

resource "aws_guardduty_detector" "hubandspoke" {
  #checkov:skip=CKV2_AWS_3:false positive
  provider = aws.hubandspoke
  enable   = true
}


###############################################################################
# Amazon Detective
#
# https://aws.github.io/aws-security-services-best-practices/guides/detective/
###############################################################################

# Side-effect: creates service-linked roles in management account only
resource "aws_detective_organization_admin_account" "this" {
  provider   = aws.management         # from
  account_id = local.audit_account_id # to
  depends_on = [
    aws_organizations_organization.this,
    aws_guardduty_organization_configuration.this,
  ]
}

resource "aws_detective_graph" "this" {
  provider   = aws.audit
  depends_on = [aws_detective_organization_admin_account.this]
  # tags = {
  #   Name = "audit-detective-graph"
  # }
}

resource "aws_detective_organization_configuration" "this" {
  provider    = aws.audit
  auto_enable = true
  graph_arn   = aws_detective_graph.this.graph_arn
}


###############################################################################
# Amazon Inspector
#
# https://aws.github.io/aws-security-services-best-practices/guides/inspector/
###############################################################################

# Side-effect: creates 2x service-linked roles in management account
# Side-effect: creates 1x service-linked role in audit account
resource "aws_inspector2_delegated_admin_account" "this" {
  provider   = aws.management         # from
  account_id = local.audit_account_id # to
  depends_on = [aws_organizations_organization.this]
}

resource "aws_inspector2_organization_configuration" "this" {
  provider = aws.audit
  auto_enable {
    ec2         = true
    ecr         = true
    lambda      = true
    lambda_code = false # Not supported in GovCloud
  }

  depends_on = [aws_inspector2_delegated_admin_account.this]
}

resource "aws_inspector2_member_association" "log" {
  provider   = aws.audit
  account_id = var.account_id_map["log"]
  depends_on = [aws_inspector2_organization_configuration.this]
}

resource "aws_inspector2_member_association" "management" {
  provider   = aws.audit
  account_id = var.account_id_map["management"]
  depends_on = [aws_inspector2_organization_configuration.this]
}

resource "aws_inspector2_member_association" "hubandspoke" {
  provider   = aws.audit
  account_id = var.account_id_map["hubandspoke"]
  depends_on = [aws_inspector2_organization_configuration.this]
}

resource "aws_inspector2_enabler" "audit" {
  provider       = aws.audit
  account_ids    = [local.audit_account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
  depends_on     = [aws_inspector2_organization_configuration.this]
}


###############################################################################
# Control Tower
#
# There are limited primitives available via the Control Tower provider.
# If additional customization is required it must be done so either (a) via the
# console or (b) using a more laborious process of creating Customizations for
# Control Tower (CfCT). Note CfCT is not available via the AWS provider.
# Here we take what the aws_control_tower_landing_zone can do for us and refine
# the configuration elsewhere.
#
# https://docs.aws.amazon.com/controltower/latest/userguide/lz-api-launch.html
# https://docs.aws.amazon.com/controltower/latest/controlreference/introduction.html
# https://repost.aws/questions/QUF9Umvk9aTkyL78HJJ-vYRg/enabling-aws-configuration-on-control-tower-main-account
#
# Control Tower creates a lot of resources in each account. For a complete list
# see https://docs.aws.amazon.com/controltower/latest/userguide/shared-account-resources.html
#
# The docs have warnings in several places about not messing with resources
# created/managed by Control Tower. Consult the Control Tower docs before
# modifying any of the following:
#   - Organizational Units (specifically Security and Sandbox OUs)
#   - Service Control Policies / guardrails managed by Control Tower
#   - Multi-account Cloudtrail
#   - Multi-account AWS Config
#   - S3 buckets for above
#   - Control Tower and Config roles in each account
# See docs for more specific warnings:
#   - https://docs.aws.amazon.com/controltower/latest/userguide/getting-started-guidance.html
#   - https://docs.aws.amazon.com/controltower/latest/userguide/orgs-guidance.html
###############################################################################

# Bug: https://github.com/hashicorp/terraform-provider-aws/issues/35763
#   Manifest schema expects num for retentionDays, but the API returns string.
#   Terraform detects this as a diff, but the manifest validation won't let you
#   submit string in those parameters. The ignore_changes ensures we don't
#   needlessly recreate this resource. If you need to make changes to manifest_json
#   then comment the lifecycle block and run apply.
# This resource has a long creation timeout of 120m, though 45m seems typical.
#   OUs created through AWS Control Tower have mandatory controls applied to them
#   automatically. The mandatory controls are documented here:
#   - https://docs.aws.amazon.com/controltower/latest/controlreference/mandatory-controls.html
# By design, Control Tower does not provision the AWSServiceRoleForConfig to the
#   management account. Security Hub will flag this as a critical finding. If you want
#   to suppress this you can add the rule to
#   aws_securityhub_configuration_policy.this.disabled_control_identifiers
#   - https://repost.aws/questions/QUF9Umvk9aTkyL78HJJ-vYRg/enabling-aws-configuration-on-control-tower-main-account
resource "aws_controltower_landing_zone" "this" {
  provider      = aws.management
  manifest_json = local.landing_zone_manifest
  version       = "3.3" # https://docs.aws.amazon.com/controltower/latest/userguide/table-of-baselines.html

  lifecycle {
    ignore_changes = [
      manifest_json
    ]
  }
}

data "aws_organizations_organizational_units" "this" {
  provider  = aws.management
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

# data "aws_controltower_controls" "this" {
#   for_each          = { for ou in data.aws_organizations_organizational_units.this.children : ou.id => ou }
#   provider          = aws.management
#   target_identifier = each.value.arn
# }


###############################################################################
# AWS Config (required before Security Hub)
#
# AWS Config is largely managed by Control Tower. See Control Tower section above
# for warnings about messing with Config resources. Explicitly delegating admin
# and setting up the conformance pack is all we need to do here.
###############################################################################

resource "aws_organizations_delegated_administrator" "config" {
  provider          = aws.management         # from
  account_id        = local.audit_account_id # to
  service_principal = "config.amazonaws.com"
  depends_on        = [aws_organizations_organization.this]
}

resource "aws_organizations_delegated_administrator" "config_multiaccountsetup" {
  provider          = aws.management         # from
  account_id        = local.audit_account_id # to
  service_principal = "config-multiaccountsetup.amazonaws.com"
  depends_on        = [aws_organizations_organization.this]
}

# https://github.com/hashicorp/terraform-provider-aws/issues/24545
# Bug: creation times out even though resource is created successfully. As a
#      result, OpenTofu automatically marks the resource as tainted. To avoid
#      unneccessary destruction on the next apply:
#      1. Check that the conformance pack in the audit account shows a deployment
#         status of "completed".
#      2. Use tofu untaint to remove the tainted status.
#   Alternatively, you can comment out this resource block and apply the
#   conformance pack manually in the AWS console.
resource "aws_config_organization_conformance_pack" "nist_800_53" {
  provider          = aws.audit
  name              = "Operational-Best-Practices-for-NIST-800-53-rev-5"
  template_body     = file("${path.module}/templates/Operational-Best-Practices-for-NIST-800-53-rev-5.yaml")
  excluded_accounts = []

  depends_on = [
    aws_controltower_landing_zone.this,
    aws_organizations_organization.this,
    aws_organizations_delegated_administrator.config,
    aws_organizations_delegated_administrator.config_multiaccountsetup,
  ]
}


###############################################################################
# AWS Security Hub
#
# https://aws.github.io/aws-security-services-best-practices/guides/security-hub/
###############################################################################

# Already exists via Control Tower
# resource "aws_securityhub_organization_admin_account" "this" {
#   provider         = aws.management
#   admin_account_id = local.audit_account_id
#   depends_on       = [aws_organizations_organization.this]
# }

# Already exists via Control Tower
# resource "aws_securityhub_finding_aggregator" "this" {
#   provider     = aws.audit
#   linking_mode = "ALL_REGIONS"
#   depends_on   = [aws_securityhub_organization_admin_account.this]
# }

# Control Tower default setting, we explicitly set it here.
resource "aws_securityhub_organization_configuration" "this" {
  provider              = aws.audit
  auto_enable           = false
  auto_enable_standards = "NONE"
  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [aws_controltower_landing_zone.this]
}

resource "aws_securityhub_configuration_policy" "this" {
  provider    = aws.audit
  name        = "cnap-default"
  description = "Default configuration policy"

  configuration_policy {
    service_enabled = true
    enabled_standard_arns = [
      "arn:${data.aws_partition.audit.partition}:securityhub:${data.aws_region.audit.name}::standards/aws-foundational-security-best-practices/v/1.0.0",
      "arn:${data.aws_partition.audit.partition}:securityhub:${data.aws_region.audit.name}::standards/nist-800-53/v/5.0.0",
    ]
    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }

  depends_on = [aws_securityhub_organization_configuration.this]
}

# Associate the policy with the root OU. Apply will complete before the policy
# fully propagates to all accounts. You can track rollout progress in the audit
# account -> Security Hub -> Settings -> Configuration -> Organization tab.
resource "aws_securityhub_configuration_policy_association" "root" {
  provider  = aws.audit
  target_id = data.aws_organizations_organization.this.roots[0].id
  policy_id = aws_securityhub_configuration_policy.this.id
}

# Using symbols in the name to ensure these are always at the top of the list
resource "aws_securityhub_insight" "critical" {
  provider = aws.audit
  name     = "__Critical Findings__"
  filters {
    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }
  group_by_attribute = "AwsAccountId"
}

# Using symbols in the name to ensure these are always at the top of the list
resource "aws_securityhub_insight" "high" {
  provider = aws.audit
  name     = "__High Findings__"
  filters {
    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
  }
  group_by_attribute = "AwsAccountId"
}


###############################################################################
# Logging
#
# Control Tower configures several types of logging:
#   - Control Tower activity logs
#   - Organization-level Cloudtrail covering all accounts
#   - Multi-account AWS Config
# In addition to Cloudwatch Logs, these logs are stored in S3 in the log account.
# It is the logs in S3 which we need to aggregate with the hubandspoke account-level
# logs in preparation for ingestion into a SIEM. Control Tower sends these logs to
# a bucket with a naming convention like:
#   - aws-controltower-logs-${log_account_id}-${ct_home_region}
#
# https://docs.aws.amazon.com/controltower/latest/userguide/logging-and-monitoring.html
###############################################################################

locals {
  # Bucket name for central log collection bucket in log account
  central_bucket_name_prefix = "${var.central_bucket_name_prefix}-${local.log_account_id}"
}
# Find the bucket where CT sends logs
data "aws_s3_bucket" "ct_logs" {
  provider   = aws.log
  bucket     = "aws-controltower-logs-${local.log_account_id}-${var.aws_region}"
  depends_on = [aws_controltower_landing_zone.this]
}

module "central_bucket" {
  providers = { aws = aws.log }
  source    = "terraform-aws-modules/s3-bucket/aws"
  version   = "~> 4.3"

  bucket                                = local.central_bucket_name_prefix
  force_destroy                         = false # prevent accidental deletion
  control_object_ownership              = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.central_logs_bucket.json

  lifecycle_rule = [
    {
      id      = "OMB-M-21-31"
      enabled = true
      filter  = {}

      transition = [
        {
          days          = 365
          storage_class = "GLACIER"
        },
      ]

      expiration = {
        days = 913
        # expired_object_delete_marker = true
      }

      # Keep the last 5 versions of a duplicate object for 30 days, then delete it
      noncurrent_version_expiration = {
        newer_noncurrent_versions = 5
        days                      = 30
      }
    },
  ]

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.central_log_bucket.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # TODO: add new bucket in log account as target for access logging recofds
  # logging = {
  #   target_bucket = module.s3_server_access_logs.s3_bucket_id
  #   target_prefix = "s3-access/"
  #   target_object_key_format = {
  #     partitioned_prefix = {
  #       partition_date_source = "DeliveryTime" # "EventTime"
  #     }
  #   }
  # }

  versioning = {
    enabled    = true
    mfa_delete = false # must be false for lifecycle rules to work
  }
}


# Aggregate CT logs to central bucket. If we need to distribute the org-level
# Cloudtrail logs to each account we can add more replication rules see link below:
# - https://repost.aws/questions/QU_Q-w35OWRhW75A69-4Kfhw/control-tower-log-sharing-with-individual-accounts
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.log
  role     = aws_iam_role.replication.arn
  bucket   = data.aws_s3_bucket.ct_logs.id

  rule {
    id     = "everything"
    status = "Enabled"
    filter {}
    delete_marker_replication {
      status = "Enabled"
    }
    source_selection_criteria {
      replica_modifications {
        status = "Enabled"
      }
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = module.central_bucket.s3_bucket_arn
      storage_class = "STANDARD"
      account       = data.aws_caller_identity.log.account_id
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.central_log_bucket.arn
      }
      access_control_translation {
        owner = "Destination"
      }
    }
  }
}

