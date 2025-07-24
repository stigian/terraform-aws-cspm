output "organization_id" {
  description = "The AWS Organization ID"
  value       = module.organizations.organization_id
}

output "management_account_id" {
  description = "Management account ID"
  value       = module.organizations.management_account_id
}

output "log_archive_account_id" {
  description = "Log archive account ID"
  value       = module.organizations.log_archive_account_id
}

output "audit_account_id" {
  description = "Audit account ID"
  value       = module.organizations.audit_account_id
}

output "account_id_map" {
  description = "Map of account names to account IDs"
  value       = module.organizations.account_id_map
}

output "organizational_unit_ids" {
  description = "Map of OU names to their IDs"
  value       = module.organizations.organizational_unit_ids
}
