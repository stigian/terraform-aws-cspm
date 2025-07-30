# Core configuration outputs
output "project" {
  description = "Project name for use by other modules"
  value       = var.project
}

output "global_tags" {
  description = "Global tags for use by other modules"
  value       = local.global_tags
}

# Organizations module inputs
output "aws_account_parameters" {
  description = "Processed account parameters for organizations module"
  value       = local.aws_account_parameters
}

output "organizational_units" {
  description = "Processed organizational units for organizations module"
  value       = local.organizational_units
}

# SSO module inputs  
output "account_id_map" {
  description = "Map of account names to account IDs for SSO module"
  value       = local.account_id_map
}

output "account_role_mapping" {
  description = "Map of account names to account types for SSO module"
  value       = local.account_role_mapping
}

# Control Tower module inputs
output "management_account_id" {
  description = "Account ID for the management account (Control Tower requirement)"
  value       = local.management_account_id
}

output "log_archive_account_id" {
  description = "Account ID for the log archive account (Control Tower requirement)"
  value       = local.log_archive_account_id
}

output "audit_account_id" {
  description = "Account ID for the audit account (Control Tower requirement)"
  value       = local.audit_account_id
}

# Security services and other module inputs
output "accounts_by_type" {
  description = "Accounts organized by SRA account type (useful for security services)"
  value       = local.accounts_by_type
}

# Raw data access (for advanced use cases)
output "raw_account_configs" {
  description = "Raw account configurations loaded from YAML (for advanced use cases)"
  value       = local.raw_account_configs
}

output "raw_ou_configs" {
  description = "Raw OU configurations loaded from YAML (for advanced use cases)"
  value       = local.raw_ou_configs
}
