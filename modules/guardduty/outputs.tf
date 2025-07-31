output "audit_detector_id" {
  description = "GuardDuty detector ID in the audit account (delegated admin)"
  value       = aws_guardduty_detector.audit.id
}

output "organization_admin_account_id" {
  description = "Account ID designated as GuardDuty organization administrator"
  value       = var.audit_account_id
}

output "organization_auto_enable" {
  description = "Whether auto-enable is configured for organization members"
  value       = aws_guardduty_organization_configuration.this.auto_enable_organization_members
}

# Protection Plan Status Outputs
output "protection_plans_enabled" {
  description = "Status of GuardDuty protection plans"
  value = {
    s3_protection          = var.enable_s3_protection
    runtime_monitoring     = var.enable_runtime_monitoring
    malware_protection_ec2 = var.enable_malware_protection_ec2
    lambda_protection      = var.enable_lambda_protection
    eks_protection         = var.enable_eks_protection
    rds_protection         = var.enable_rds_protection
    malware_protection_s3  = var.enable_malware_protection_s3
  }
}

output "s3_protection_feature_id" {
  description = "GuardDuty S3 Protection feature ID (if enabled)"
  value       = var.enable_s3_protection ? aws_guardduty_detector_feature.s3_protection[0].id : null
}

output "runtime_monitoring_feature_id" {
  description = "GuardDuty Runtime Monitoring feature ID (if enabled)"
  value       = var.enable_runtime_monitoring ? aws_guardduty_detector_feature.runtime_monitoring[0].id : null
}
