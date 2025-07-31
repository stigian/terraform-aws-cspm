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
