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

resource "aws_kms_key" "key" {
  provider            = aws.audit
  description         = "KMS key for AWS Config aggregator"
  enable_key_rotation = true
  tags                = var.global_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAuditAccountKeyManagement"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${var.audit_account_id}:root"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid       = "AllowOrgDecrypt"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "AWS:SourceOrgID" = var.organization_id
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "key_alias" {
  provider      = aws.audit
  name          = "alias/cnscca-org-config-aggregator"
  target_key_id = aws_kms_key.key.key_id
}

resource "aws_s3_bucket" "delivery" {
  provider      = aws.audit
  bucket        = "cnscca-org-config-aggregator-${var.audit_account_id}"
  tags          = var.global_tags
  force_destroy = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  provider = aws.audit
  bucket   = aws_s3_bucket.delivery.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.delivery.arn
        Condition = {
          StringEquals = { "AWS:SourceOrgID" = var.organization_id }
        }
      },
      {
        Sid       = "AWSConfigBucketExistenceCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.delivery.arn
        Condition = {
          StringEquals = { "AWS:SourceOrgID" = var.organization_id }
        }
      },
      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.delivery.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"    = "bucket-owner-full-control"
            "AWS:SourceOrgID" = var.organization_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "delivery" {
  provider = aws.audit
  bucket   = aws_s3_bucket.delivery.id

  rule {
    id     = "OMB-M-21-31"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER_IR"
    }
    expiration {
      days = 913
    }

    filter {}
  }
}

resource "aws_iam_role" "aggregator" {
  provider = aws.audit
  name     = "AWSConfigAggregatorRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy" "aggregator" {
  name = "AWSConfigRoleForOrganizations"
}

resource "aws_iam_role_policy_attachment" "aggregator_policy" {
  provider   = aws.audit
  role       = aws_iam_role.aggregator.name
  policy_arn = data.aws_iam_policy.aggregator.arn
}

resource "aws_config_configuration_aggregator" "org" {
  provider = aws.audit
  name     = var.aggregator_name

  organization_aggregation_source {
    role_arn    = aws_iam_role.aggregator.arn
    all_regions = var.aggregator_all_regions
  }

  depends_on = [
    aws_organizations_delegated_administrator.config,
    aws_organizations_delegated_administrator.config_multiaccountsetup,
  ]
}
