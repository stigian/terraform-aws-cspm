###############################################################################
# GuardDuty Module Outputs
###############################################################################

# Comprehensive GuardDuty status for compliance and operational visibility
output "guardduty_status" {
  description = "Complete GuardDuty deployment status including organization configuration and protection plans"
  value = {
    # Core detector information
    admin_account_id    = var.audit_account_id
    audit_detector_id   = aws_guardduty_detector.audit.id
    auto_enable_enabled = aws_guardduty_organization_configuration.this.auto_enable_organization_members

    # Protection plan configuration - shows what capabilities are active
    protection_plans = {
      # Priority 1 - Core data protection
      s3_protection          = var.enable_s3_protection
      runtime_monitoring     = var.enable_runtime_monitoring
      malware_protection_ec2 = var.enable_malware_protection_ec2

      # Priority 2 - Service-specific protection  
      lambda_protection     = var.enable_lambda_protection
      eks_protection        = var.enable_eks_protection
      rds_protection        = var.enable_rds_protection
      malware_protection_s3 = var.enable_malware_protection_s3
    }
  }
}
