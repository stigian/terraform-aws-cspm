data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {}

# Load AWS Security Reference Architecture (SRA) Account Types from YAML
# These match accreditation requirements and cannot be changed
locals {
  sra_account_types = yamldecode(file("${path.module}/../../config/sra-account-types.yaml"))

  # Extract just the account type names for validation
  valid_account_types = keys(local.sra_account_types)
}

###############################################################################
# Control Tower Service Roles
#
# These roles are required before Control Tower landing zone can be created
# https://docs.aws.amazon.com/controltower/latest/userguide/lz-api-prereques.html
# https://docs.aws.amazon.com/controltower/latest/userguide/access-control-managing-permissions.html
###############################################################################

resource "aws_iam_role" "controltower_admin" {
  name = "AWSControlTowerAdmin"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "controltower.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.global_tags, {
    Name = "AWSControlTowerAdmin"
  })
}

resource "aws_iam_role_policy" "controltower_admin" {
  name = "AWSControlTowerAdminPolicy"
  role = aws_iam_role.controltower_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2:DescribeAvailabilityZones"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "controltower_admin" {
  role       = aws_iam_role.controltower_admin.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSControlTowerServiceRolePolicy"
}

resource "aws_iam_role" "controltower_cloudformation" {
  name = "AWSControlTowerCloudTrailRole"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.global_tags, {
    Name = "AWSControlTowerCloudTrailRole"
  })
}

resource "aws_iam_role_policy" "controltower_cloudformation" {
  name = "AWSControlTowerCloudTrailRolePolicy"
  role = aws_iam_role.controltower_cloudformation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:CreateLogStream"
        Resource = "arn:${data.aws_partition.current.partition}:logs:*:*:log-group:aws-controltower/CloudTrailLogs:*"
        Effect   = "Allow"
      },
      {
        Action   = "logs:PutLogEvents"
        Resource = "arn:${data.aws_partition.current.partition}:logs:*:*:log-group:aws-controltower/CloudTrailLogs:*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "controltower_stackset" {
  name = "AWSControlTowerStackSetRole"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudformation.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.global_tags, {
    Name = "AWSControlTowerStackSetRole"
  })
}

resource "aws_iam_role_policy" "controltower_stackset" {
  name = "AWSControlTowerStackSetRolePolicy"
  role = aws_iam_role.controltower_stackset.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:iam::*:role/AWSControlTowerExecution"
        ]
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "controltower_config" {
  name = "AWSControlTowerConfigAggregatorRoleForOrganizations"
  path = "/service-role/"

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

  tags = merge(var.global_tags, {
    Name = "AWSControlTowerConfigAggregatorRoleForOrganizations"
  })
}

# https://docs.aws.amazon.com/controltower/latest/userguide/roles-how.html#config-role-for-organizations
resource "aws_iam_role_policy_attachment" "controltower_config_organizations" {
  role       = aws_iam_role.controltower_config.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

###############################################################################
# AWSControlTowerExecution Roles for Member Accounts
#
# These roles are required in log archive and audit accounts before Control Tower
# can bootstrap the landing zone infrastructure in those accounts
# https://docs.aws.amazon.com/controltower/latest/userguide/roles-how.html
###############################################################################

# AWSControlTowerExecution role in log archive account
resource "aws_iam_role" "execution_role_log_archive" {
  provider = aws.log_archive
  name     = "AWSControlTowerExecution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.global_tags, {
    Name = "AWSControlTowerExecution"
  })
}

resource "aws_iam_role_policy_attachment" "execution_role_log_archive" {
  provider   = aws.log_archive
  role       = aws_iam_role.execution_role_log_archive.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}

# AWSControlTowerExecution role in audit account
resource "aws_iam_role" "execution_role_audit" {
  provider = aws.audit
  name     = "AWSControlTowerExecution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.global_tags, {
    Name = "AWSControlTowerExecution"
  })
}

resource "aws_iam_role_policy_attachment" "execution_role_audit" {
  provider   = aws.audit
  role       = aws_iam_role.execution_role_audit.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}

locals {
  landing_zone_manifest = var.deploy_landing_zone ? templatefile("${path.module}/templates/LandingZoneManifest.tpl.json", {
    logging_account_id        = var.log_archive_account_id
    security_account_id       = var.audit_account_id
    kms_key_arn               = aws_kms_key.control_tower.arn
    access_management_enabled = !var.self_managed_sso # Invert: self_managed means CT SSO disabled
  }) : null

  # Add Project tag to global tags
  global_tags = merge(var.global_tags, {
    Project = var.project
  })
}

resource "aws_controltower_landing_zone" "this" {
  count         = var.deploy_landing_zone ? 1 : 0
  manifest_json = local.landing_zone_manifest
  version       = "3.3"

  # Ensure service roles and execution roles are created first
  depends_on = [
    aws_iam_role_policy.controltower_admin,
    aws_iam_role_policy_attachment.controltower_admin,
    aws_iam_role_policy.controltower_cloudformation,
    aws_iam_role_policy.controltower_stackset,
    aws_iam_role_policy_attachment.controltower_config_organizations,
    aws_iam_role_policy_attachment.execution_role_log_archive,
    aws_iam_role_policy_attachment.execution_role_audit
  ]

  # Note: Ignore manifest_json changes due to API string/number type inconsistencies
  # Comment out this lifecycle block if you need to update the manifest
  lifecycle {
    ignore_changes = [manifest_json]
  }
}

# Control Tower KMS key for Config and CloudTrail
# https://docs.aws.amazon.com/controltower/latest/userguide/configure-kms-keys.html

resource "aws_kms_alias" "control_tower" {
  name          = "alias/control-tower-key"
  target_key_id = aws_kms_key.control_tower.key_id
}

resource "aws_kms_key" "control_tower" {
  description             = "KMS key for Control Tower resource encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.global_tags, {
    Name = "control-tower-key"
  })
}

resource "aws_kms_key_policy" "control_tower" {
  key_id = aws_kms_key.control_tower.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "control-tower-key-policy"
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
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.control_tower.arn
      },
      {
        Sid    = "Allow Key Administrators and SSO Admin Roles"
        Effect = "Allow"
        Principal = {
          AWS = concat([
            data.aws_caller_identity.current.arn,
            "arn:${data.aws_partition.current.partition}:iam::${var.management_account_id}:root"
          ], var.additional_kms_key_admin_arns)
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
        Sid    = "Allow Config Service Cross-Account"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = aws_kms_key.control_tower.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = data.aws_organizations_organization.current.id
          }
        }
      },
      {
        Sid    = "Allow CloudTrail Service with Enhanced Controls"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:CreateGrant"
        ]
        Resource = aws_kms_key.control_tower.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${var.management_account_id}:trail/aws-controltower-BaselineCloudTrail"
          },
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:${data.aws_partition.current.partition}:cloudtrail:*:${var.management_account_id}:trail/*"
          }
        }
      }
    ]
  })
}

# Control Tower Notes:
#
# Limited customization available via Terraform provider - additional changes require
# AWS Console or Customizations for Control Tower (CfCT).
#
# IMPORTANT: Do not modify Control Tower-managed resources:
#   - Security/Sandbox OUs and their guardrails  
#   - Multi-account CloudTrail/Config
#   - Control Tower service roles
#   - Log aggregation S3 buckets
#
# Resources: 
# - Landing Zone API: https://docs.aws.amazon.com/controltower/latest/userguide/lz-api-launch.html
# - Control Reference: https://docs.aws.amazon.com/controltower/latest/controlreference/introduction.html
# - Shared Resources: https://docs.aws.amazon.com/controltower/latest/userguide/shared-account-resources.html
