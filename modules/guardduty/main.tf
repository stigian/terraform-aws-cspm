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
