output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = module.organizations.organization_id
}

output "organizational_unit_ids" {
  description = "Map of OU names to their IDs"
  value       = module.organizations.organizational_unit_ids
}

output "account_id_map" {
  description = "Map of account names to account IDs"
  value       = module.organizations.account_id_map
}

output "management_account_id" {
  description = "The account ID of the management account"
  value       = module.organizations.management_account_id
}

output "log_archive_account_id" {
  description = "The account ID of the log archive account"
  value       = module.organizations.log_archive_account_id
}

output "audit_account_id" {
  description = "The account ID of the audit account"
  value       = module.organizations.audit_account_id
}

output "accounts_by_type" {
  description = "Accounts organized by their SRA account type"
  value       = module.organizations.accounts_by_type
}

output "sso_management_enabled" {
  description = "Whether SSO management is enabled"
  value       = module.sso.sso_management_enabled
}

output "control_tower_detected" {
  description = "Whether Control Tower was detected managing the organization"
  value       = module.sso.control_tower_detected
}
