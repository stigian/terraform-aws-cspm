# REFS:
#   - https://aws.amazon.com/blogs/publicsector/aws-federal-customers-memorandum-m-21-31/
#   - https://bidenwhitehouse.archives.gov/wp-content/uploads/2021/08/M-21-31-Improving-the-Federal-Governments-Investigative-and-Remediation-Capabilities-Related-to-Cybersecurity-Incidents.pdf

data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {

  # These buckets are created ahead of time by the CSPM module.
  # These names must remain consistent with what is declared in the cspm/main.tf file
  bucket_names = {
    s3_access_logs = "hubandspoke-s3-access-logs-${var.identifier}-${var.account_id_map["hubandspoke"]}"
    lb_logs        = "hubandspoke-lb-logs-${var.identifier}-${var.account_id_map["hubandspoke"]}"
    vpc_flow_logs  = "hubandspoke-flow-logs-${var.identifier}-${var.account_id_map["hubandspoke"]}"
    waf_logs       = "aws-waf-logs-${var.identifier}-${var.account_id_map["hubandspoke"]}" # Name must start with aws-waf-logs
    anfw_logs      = "hubandspoke-anfw-logs-${var.identifier}-${var.account_id_map["hubandspoke"]}"
    central_logs   = "${var.central_bucket_name_prefix}-${var.account_id_map["log"]}"
    org_cloudtrail = "org-cloudtrail-logs-${var.identifier}-${var.account_id_map["hubandspoke"]}"
    org_config     = "org-config-logs-${var.identifier}-${var.account_id_map["hubandspoke"]}"
  }

  central_logs_config = {
    bucket             = "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["central_logs"]}"
    storage_class      = "STANDARD"
    replica_kms_key_id = "arn:${data.aws_partition.current.partition}:kms:${data.aws_region.name}:${var.account_id_map["log"]}:alias/central-log-objects"
    account_id         = var.account_id_map["log"]

    access_control_translation = {
      owner = "Destination"
    }
  }

  # OMB-M-21-31 compliant lifecycle rule
  # 30 months total == 12 months active, 18 months cold, then delete
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
}

# resource "random_pet" "this" {
#   length = 2
# }


###############################################################################
# S3 Access Logs
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html
###############################################################################

module "s3_server_access_logs" {
  providers = { aws = aws.hubandspoke }

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.3"

  bucket                                     = local.bucket_names["s3_access_logs"]
  lifecycle_rule                             = local.lifecycle_rule
  force_destroy                              = true
  control_object_ownership                   = true
  attach_access_log_delivery_policy          = true
  attach_deny_insecure_transport_policy      = true
  attach_require_latest_tls_policy           = true
  access_log_delivery_policy_source_accounts = [data.aws_caller_identity.current.account_id]
  access_log_delivery_policy_source_buckets  = [] # ["arn:${data.aws_partition.current.partition}:s3:::${TODO}"]

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.hubandspoke_s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    enabled    = true
    mfa_delete = false # must be false for lifecycle rules to work
  }

  replication_configuration = {
    role = aws_iam_role.central_logs.arn

    rules = [
      {
        id                        = "everything"
        status                    = "Enabled"
        destination               = local.central_logs_config
        delete_marker_replication = true
        source_selection_criteria = {
          replica_modifications = {
            status = "Enabled"
          }
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
      },
    ]
  }
}


###############################################################################
# VPC Flow Logs
###############################################################################

module "s3_vpc_flow_logs" {
  providers = { aws = aws.hubandspoke }

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.3"

  bucket                                = local.bucket_names["vpc_flow_logs"]
  lifecycle_rule                        = local.lifecycle_rule
  force_destroy                         = true
  control_object_ownership              = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.s3_vpc_flow_logs.json
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.hubandspoke_s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging = {
    target_bucket = module.s3_server_access_logs.s3_bucket_id
    target_prefix = "s3-access/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "DeliveryTime" # "EventTime"
      }
    }
  }

  versioning = {
    enabled    = true
    mfa_delete = false # must be false for lifecycle rules to work
  }

  replication_configuration = {
    role = aws_iam_role.central_logs.arn

    rules = [
      {
        id                        = "everything"
        status                    = "Enabled"
        destination               = local.central_logs_config
        delete_marker_replication = true
        source_selection_criteria = {
          replica_modifications = {
            status = "Enabled"
          }
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
      },
    ]
  }
}

data "aws_iam_policy_document" "s3_vpc_flow_logs" {
  provider = aws.hubandspoke

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${module.s3_vpc_flow_logs.s3_bucket_arn}/AWSLogs/*",
      # "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["vpc_flow_logs"]}/AWSLogs/*"
    ]
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [
      "${module.s3_vpc_flow_logs.s3_bucket_arn}",
      # "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["vpc_flow_logs"]}"
    ]
  }
}


###############################################################################
# Load Balancer Logs
###############################################################################

module "s3_lb_logs" {
  providers = { aws = aws.hubandspoke }

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.3"

  bucket                                = local.bucket_names["lb_logs"]
  lifecycle_rule                        = local.lifecycle_rule
  force_destroy                         = true
  control_object_ownership              = true
  attach_elb_log_delivery_policy        = true
  attach_lb_log_delivery_policy         = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        #checkov:skip=CKV_AWS_145: best we can do here, ELB logs only support SSE-S3
        sse_algorithm = "AES256"
      }
    }
  }

  logging = {
    target_bucket = module.s3_server_access_logs.s3_bucket_id
    target_prefix = "s3-access/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "DeliveryTime" # "EventTime"
      }
    }
  }

  versioning = {
    enabled    = true
    mfa_delete = false # must be false for lifecycle rules to work
  }

  replication_configuration = {
    role = aws_iam_role.central_logs.arn

    rules = [
      {
        id                        = "everything"
        status                    = "Enabled"
        destination               = local.central_logs_config
        delete_marker_replication = true
        source_selection_criteria = {
          replica_modifications = {
            status = "Enabled"
          }
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
      },
    ]
  }
}


###############################################################################
# WAF Logs
###############################################################################

module "s3_waf_logs" {
  providers = { aws = aws.hubandspoke }

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.3"

  bucket                                = local.bucket_names["waf_logs"]
  lifecycle_rule                        = local.lifecycle_rule
  force_destroy                         = true
  control_object_ownership              = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.waf_logs.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.hubandspoke_s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging = {
    target_bucket = module.s3_server_access_logs.s3_bucket_id
    target_prefix = "s3-access/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "DeliveryTime" # "EventTime"
      }
    }
  }

  versioning = {
    enabled    = true
    mfa_delete = false # must be false for lifecycle rules to work
  }

  replication_configuration = {
    role = aws_iam_role.central_logs.arn

    rules = [
      {
        id                        = "everything"
        status                    = "Enabled"
        destination               = local.central_logs_config
        delete_marker_replication = true
        source_selection_criteria = {
          replica_modifications = {
            status = "Enabled"
          }
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
      },
    ]
  }
}

data "aws_iam_policy_document" "waf_logs" {
  provider = aws.hubandspoke

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["waf_logs"]}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:GetBucketAcl"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["waf_logs"]}",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}


###############################################################################
# Network Firewall
###############################################################################

module "s3_anfw_logs" {
  providers = { aws = aws.hubandspoke }

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.3"

  bucket                                = local.bucket_names["anfw_logs"]
  lifecycle_rule                        = local.lifecycle_rule
  force_destroy                         = true
  control_object_ownership              = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.anfw_logs.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.hubandspoke_s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging = {
    target_bucket = module.s3_server_access_logs.s3_bucket_id
    target_prefix = "s3-access/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "DeliveryTime" # "EventTime"
      }
    }
  }

  versioning = {
    enabled    = true
    mfa_delete = false # must be false for lifecycle rules to work
  }

  replication_configuration = {
    role = aws_iam_role.central_logs.arn

    rules = [
      {
        id                        = "everything"
        status                    = "Enabled"
        destination               = local.central_logs_config
        delete_marker_replication = true
        source_selection_criteria = {
          replica_modifications = {
            status = "Enabled"
          }
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
      },
    ]
  }
}

# https://docs.aws.amazon.com/network-firewall/latest/developerguide/logging-s3.html
data "aws_iam_policy_document" "anfw_logs" {
  provider = aws.hubandspoke

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["anfw_logs"]}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:GetBucketAcl"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["anfw_logs"]}",
    ]
  }
}


###############################################################################
# Central Logs
#
# These resources allows S3 in the hub-and-spoke accounts to replicate logs to
# the log archive account.
#
# REFS:
#   - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html#replication-walkthrough-4
#   - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-walkthrough-2.html
#   - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-troubleshoot.html
###############################################################################

data "aws_iam_policy_document" "central_logs_assume_role" {
  provider = aws.log

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "central_logs" {
  provider = aws.log

  name               = "hubandspoke-central-logs-replication"
  assume_role_policy = data.aws_iam_policy_document.central_logs_assume_role.json
}

data "aws_iam_policy_document" "central_logs" {
  provider = aws.log

  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["access_logs"]}",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["lb_logs"]}",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["flow_logs"]}",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["waf_logs"]}",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["anfw_logs"]}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["access_logs"]}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["lb_logs"]}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["flow_logs"]}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["waf_logs"]}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["anfw_logs"]}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_names["central_logs"]}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      aws_kms_key.hubandspoke_s3.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      aws_kms_key.hubandspoke_s3.arn,
      aws_kms_key.central_bucket,
    ]
  }
}

resource "aws_iam_policy" "central_logs" {
  provider = aws.log

  name   = "${local.bucket_names["central_logs"]}-policy"
  policy = data.aws_iam_policy_document.central_logs.json
}

resource "aws_iam_role_policy_attachment" "central_logs" {
  provider = aws.log

  role       = aws_iam_role.central_logs.name
  policy_arn = aws_iam_policy.central_logs.arn
}


###############################################################################
# KMS for hubandspoke log object encryption
###############################################################################

resource "aws_kms_alias" "hubandspoke_s3" {
  provider = aws.hubandspoke

  name          = "alias/hubandspoke-log-objects-${var.identifier}"
  target_key_id = aws_kms_key.hubandspoke_s3.key_id
}

resource "aws_kms_key" "hubandspoke_s3" {
  provider = aws.hubandspoke

  description             = "KMS key is used to encrypt hubandspoke log bucket objects"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "hubandspoke-log-objects-${var.identifier}"
  }
}

resource "aws_kms_key_policy" "hubandspoke_s3" {
  provider = aws.hubandspoke

  key_id = aws_kms_key.hubandspoke_s3.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "hubandspoke-log-objects-key-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = [
            data.aws_caller_identity.current.arn,
            "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = concat([
            [data.aws_caller_identity.current.arn],
            var.key_admin_arns,
          ])
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow services to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "delivery.logs.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = data.aws_organizations_organization.current.id
          }
        }
      }
    ]
  })
}


###############################################################################
# Cloudtrail and Config
#
# These buckets are created in the hubandspoke account to receive replicated
# logs from the control Tower bucket in the log archive account. This makes it
# easier to ingest those logs into Splunk, and ensures that any meaningful
# infrastructure remains within the hubandspoke account where it is monitored.
###############################################################################

module "s3_org_cloudtrail_logs" {
  providers = { aws = aws.hubandspoke }
  source    = "terraform-aws-modules/s3-bucket/aws"
  version   = "~> 4.3"

  bucket                                = local.bucket_names["org_cloudtrail"]
  force_destroy                         = true
  control_object_ownership              = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.log_delivery.json

  lifecycle_rule = local.lifecycle_rule

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.hubandspoke_s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  logging = {
    target_bucket = module.s3_server_access_logs.s3_bucket_id
    target_prefix = "org-cloudtrail/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "DeliveryTime" # "EventTime"
      }
    }
  }

  versioning = {
    enabled    = true
    mfa_delete = false # must be false for lifecycle rules to work
  }
}

module "s3_org_config_logs" {
  providers = { aws = aws.hubandspoke }
  source    = "terraform-aws-modules/s3-bucket/aws"
  version   = "~> 4.3"

  bucket                                = local.bucket_names["org_config"]
  force_destroy                         = true
  control_object_ownership              = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.log_delivery.json

  lifecycle_rule = local.lifecycle_rule

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.hubandspoke_s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  logging = {
    target_bucket = module.s3_server_access_logs.s3_bucket_id
    target_prefix = "org-config/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "DeliveryTime" # "EventTime"
      }
    }
  }

  versioning = {
    enabled    = true
    mfa_delete = false # must be false for lifecycle rules to work
  }
}

# Allows S3 service in the log account to replicate logs to the hubandspoke account
data "aws_iam_policy_document" "log_delivery" {
  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${module.s3_org_cloudtrail_logs.s3_bucket_arn}/*",
      "${module.s3_org_config_logs.s3_bucket_arn}/*",
    ]
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [
      module.s3_org_cloudtrail_logs.s3_bucket_arn,
      module.s3_org_config_logs.s3_bucket_arn,
    ]
  }
}
