# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create-service-linked-role.html#create-service-linked-role
# https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_aws-services-that-work-with-iam.html


###############################################################################
# Service-Linked Roles
#
# Provision remaining service-linked roles where main.tf does not create them.
# Note: Control Tower does not provision AWSServiceRoleForconfig in the management
#       account. As a result, Security Hub will show a critical finding for this.
#       This is apparntly the expected behavior. See the following for more info:
#       - https://repost.aws/questions/QUF9Umvk9aTkyL78HJJ-vYRg/enabling-aws-configuration-on-control-tower-main-account
###############################################################################

resource "aws_iam_service_linked_role" "log_detective" {
  provider         = aws.log
  aws_service_name = "detective.amazonaws.com"
}

resource "aws_iam_service_linked_role" "audit_detective" {
  provider         = aws.audit
  aws_service_name = "detective.amazonaws.com"
}

resource "aws_iam_service_linked_role" "hubandspoke_detective" {
  provider         = aws.hubandspoke
  aws_service_name = "detective.amazonaws.com"
}

resource "aws_iam_service_linked_role" "log_inspector2" {
  provider         = aws.log
  aws_service_name = "inspector2.amazonaws.com"
}

resource "aws_iam_service_linked_role" "hubandspoke_inspector2" {
  provider         = aws.hubandspoke
  aws_service_name = "inspector2.amazonaws.com"
}

resource "aws_iam_service_linked_role" "log_agentless_inspector2" {
  provider         = aws.log
  aws_service_name = "agentless.inspector2.amazonaws.com"
}

resource "aws_iam_service_linked_role" "audit_agentless_inspector2" {
  provider         = aws.audit
  aws_service_name = "agentless.inspector2.amazonaws.com"
}

resource "aws_iam_service_linked_role" "hubandspoke_agentless_inspector2" {
  provider         = aws.hubandspoke
  aws_service_name = "agentless.inspector2.amazonaws.com"
}

# resource "aws_iam_service_linked_role" "ct_admin" {
#   provider         = aws.management
#   aws_service_name = "controltower.amazonaws.com"
# }

# resource "aws_iam_service_linked_role" "ct_cloudtrail" {
#   provider         = aws.management
#   aws_service_name = "agentless.inspector2.amazonaws.com"
# }

# resource "aws_iam_service_linked_role" "ct_stackset" {
#   provider         = aws.management
#   aws_service_name = "agentless.inspector2.amazonaws.com"
# }

# resource "aws_iam_service_linked_role" "ct_config" {
#   provider         = aws.management
#   aws_service_name = "agentless.inspector2.amazonaws.com"
# }


###############################################################################
# KMS
###############################################################################

# -- Control Tower KMS key for Config and CloudTrail ---
# https://docs.aws.amazon.com/controltower/latest/userguide/configure-kms-keys.html

resource "aws_kms_alias" "control_tower" {
  provider      = aws.management
  name          = "alias/control-tower-key"
  target_key_id = aws_kms_key.control_tower.key_id
}

resource "aws_kms_key" "control_tower" {
  provider                = aws.management
  description             = "KMS key for Control Tower resource encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "control-tower-key"
  }
}

resource "aws_kms_key_policy" "control_tower" {
  provider = aws.management
  key_id   = aws_kms_key.control_tower.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "control-tower-key-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = [
            data.aws_caller_identity.management.arn,
            "arn:${data.aws_partition.management.partition}:iam::${data.aws_caller_identity.management.account_id}:root"
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
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = [
            data.aws_caller_identity.management.arn,
          ]
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
        Resource = aws_kms_key.control_tower.arn
      },
      {
        Sid    = "Allow Config to use KMS for encryption"
        Effect = "Allow"
        Principal = {
          Service = ["config.amazonaws.com"]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.control_tower.arn
      },
      {
        Sid    = "Allow CloudTrail to use KMS for encryption"
        Effect = "Allow"
        Principal = {
          Service = ["cloudtrail.amazonaws.com"]
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.control_tower.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:${data.aws_partition.management.partition}:cloudtrail:${var.aws_region}:${local.management_account_id}:trail/aws-controltower-BaselineCloudTrail"
          },
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:${data.aws_partition.management.partition}:cloudtrail:*:${local.management_account_id}:trail/*"
          }
        }
      }
    ]
  })
}


# -- Central logs bucket and key ---

# Find the AWSAdministratorAccess role provisioned by Control Tower
# https://docs.aws.amazon.com/controltower/latest/userguide/sso-groups.html
data "aws_iam_roles" "log_sso_admin" {
  provider    = aws.log
  name_regex  = "AWSReservedSSO_AWSAdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
  depends_on  = [aws_controltower_landing_zone.this]
}

resource "aws_kms_alias" "central_log_bucket" {
  provider      = aws.log
  name          = "alias/central-log-objects"
  target_key_id = aws_kms_key.central_log_bucket.key_id
}

resource "aws_kms_key" "central_log_bucket" {
  provider                = aws.log
  description             = "KMS key is used to encrypt central log objects"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "central-log-bucket-key"
  }
}

resource "aws_kms_key_policy" "central_log_bucket" {
  provider = aws.log
  key_id   = aws_kms_key.central_log_bucket.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "kms-key-policy-central-logs"
    Statement = [
      {
        Sid    = "Allow replication roles to use this key"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:${data.aws_partition.hubandspoke.partition}:iam::${local.hubandspoke_account_id}:role/${var.replication_role_name}",
            resource.aws_iam_role.replication.arn,
            # "arn:${data.aws_partition.hubandspoke.partition}:iam::${local.hubandspoke_account_id}:root"
          ]
        }
        Action = [
          "kms:Encrypt",
          # "kms:Decrypt",
          # "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          # "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = concat(
            [data.aws_caller_identity.log.arn],            # OrganizationAccountAccessRole
            tolist(data.aws_iam_roles.log_sso_admin.arns), # AWSReservedSSO_AWSAdministratorAccess_*
            ["arn:${data.aws_partition.log.partition}:iam::${data.aws_caller_identity.log.account_id}:root"]
          )
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = concat(
            [data.aws_caller_identity.log.arn],            # OrganizationAccountAccessRole
            tolist(data.aws_iam_roles.log_sso_admin.arns), # AWSReservedSSO_AWSAdministratorAccess_*
          )
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
      }
    ]
  })
}


# -- Replication from CT to central logs bucket ---

data "aws_iam_policy_document" "s3_assume_role" {
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

resource "aws_iam_role" "replication" {
  provider           = aws.log
  name               = "ct-central-logs-replication"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}

data "aws_iam_policy_document" "replication" {
  provider = aws.log
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [data.aws_s3_bucket.ct_logs.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${data.aws_s3_bucket.ct_logs.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = [
      "arn:${data.aws_partition.log.partition}:s3:::${module.central_bucket.s3_bucket_id}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      aws_kms_key.control_tower.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      aws_kms_key.central_log_bucket.arn
    ]
  }
}

resource "aws_iam_policy" "replication" {
  provider = aws.log
  name     = "ct-central-logs-replication"
  policy   = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  provider   = aws.log
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}


# Bucket policy to allow replication of objects from hubandspoke and control tower
# to central logs bucket in log account.
#   https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-walkthrough-2.html
# TODO: review for best practices concerning conditions, see:
#   https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html
data "aws_iam_policy_document" "central_logs_bucket" {
  provider = aws.log
  statement {
    sid    = "Permissions on objects"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.hubandspoke.partition}:iam::${local.hubandspoke_account_id}:role/${var.replication_role_name}",
        aws_iam_role.replication.arn,
      ]
    }
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${module.central_bucket.s3_bucket_arn}/*"]
  }

  statement {
    sid    = "Permissions on bucket"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.hubandspoke.partition}:iam::${local.hubandspoke_account_id}:role/${var.replication_role_name}",
        resource.aws_iam_role.replication.arn,
      ]
    }
    actions = [
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [module.central_bucket.s3_bucket_arn]
  }

  statement {
    sid       = "Allow access from docker-splunk in hubandspoke"
    effect    = "Allow"
    principal = "*"
    action = [
      "s3:GetObject",
    ]
    resource = [
      "${module.central_bucket.s3_bucket_arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:ResourceAccount"
      values = [
        local.hubandspoke_account_id,
        local.management_account_id
      ]
    }
  }
}
