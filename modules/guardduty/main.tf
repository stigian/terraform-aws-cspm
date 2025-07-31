###############################################################################
# Amazon GuardDuty - Organization Management
#
# This module configures organization-wide GuardDuty with a delegated administrator.
# AWS automatically creates and manages GuardDuty detectors in ALL accounts when
# auto_enable_organization_members = "ALL" is configured.
#
# Benefits:
# - Scalable: Works with any number of accounts
# - Future-proof: New accounts automatically get GuardDuty enabled
# - Simplified: AWS manages detector creation in all accounts
#
# https://aws.github.io/aws-security-services-best-practices/guides/guardduty/
###############################################################################

# Step 1: Designate audit account as GuardDuty organization administrator
# This is done from the management account (default provider)
resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = var.audit_account_id
}

# Step 2: Create GuardDuty detector in audit account (required for org management)
# The delegated admin account needs its detector created first
resource "aws_guardduty_detector" "audit" {
  #checkov:skip=CKV2_AWS_3:false positive
  provider = aws.audit
  enable   = true

  tags = merge(
    var.global_tags,
    {
      Account     = var.audit_account_id
      AccountType = "audit"
      ManagedBy   = "GuardDuty-Organization-Admin"
    }
  )
}

# Step 3: Configure organization-wide GuardDuty settings
# IMPORTANT: This automatically creates and manages GuardDuty detectors in ALL member accounts
# AWS will create detectors in member accounts, but the delegated admin detector must exist first
resource "aws_guardduty_organization_configuration" "this" {
  #checkov:skip=CKV2_AWS_3:false positive
  provider                         = aws.audit
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.audit.id

  depends_on = [aws_guardduty_organization_admin_account.this]
}

###############################################################################
# GuardDuty Protection Plans Configuration
# 
# These features provide enhanced threat detection capabilities beyond the
# foundational GuardDuty monitoring of CloudTrail, VPC Flow Logs, and DNS logs.
#
# Reference: https://docs.aws.amazon.com/guardduty/latest/ug/guardduty-features-activation-model.html
###############################################################################

# Priority 1: S3 Protection - Monitor S3 data events for suspicious access
resource "aws_guardduty_detector_feature" "s3_protection" {
  count       = var.enable_s3_protection ? 1 : 0
  provider    = aws.audit
  detector_id = aws_guardduty_detector.audit.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"

  depends_on = [aws_guardduty_organization_configuration.this]
}

# Priority 1: Runtime Monitoring - eBPF-based OS-level monitoring for EC2/EKS/ECS
resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  count       = var.enable_runtime_monitoring ? 1 : 0
  provider    = aws.audit
  detector_id = aws_guardduty_detector.audit.id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  depends_on = [aws_guardduty_organization_configuration.this]
}

# Priority 1: Malware Protection for EC2 - Scan EBS volumes when threats detected
resource "aws_guardduty_detector_feature" "malware_protection_ec2" {
  count       = var.enable_malware_protection_ec2 ? 1 : 0
  provider    = aws.audit
  detector_id = aws_guardduty_detector.audit.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"

  depends_on = [aws_guardduty_organization_configuration.this]
}

# Priority 2: Lambda Protection - Monitor Lambda VPC network activity
resource "aws_guardduty_detector_feature" "lambda_protection" {
  count       = var.enable_lambda_protection ? 1 : 0
  provider    = aws.audit
  detector_id = aws_guardduty_detector.audit.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "ENABLED"

  depends_on = [aws_guardduty_organization_configuration.this]
}

# Priority 2: EKS Protection - Monitor Kubernetes audit logs
resource "aws_guardduty_detector_feature" "eks_protection" {
  count       = var.enable_eks_protection ? 1 : 0
  provider    = aws.audit
  detector_id = aws_guardduty_detector.audit.id
  name        = "EKS_AUDIT_LOGS"
  status      = "ENABLED"

  depends_on = [aws_guardduty_organization_configuration.this]
}

# Priority 2: RDS Protection - Monitor Aurora database login activity
resource "aws_guardduty_detector_feature" "rds_protection" {
  count       = var.enable_rds_protection ? 1 : 0
  provider    = aws.audit
  detector_id = aws_guardduty_detector.audit.id
  name        = "RDS_LOGIN_EVENTS"
  status      = "ENABLED"

  depends_on = [aws_guardduty_organization_configuration.this]
}
