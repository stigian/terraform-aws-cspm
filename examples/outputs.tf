output "organization_summary" {
  description = "Summary of the AWS organization setup"
  value = {
    organization_id = module.organizations.organization_id
    account_count   = length(module.organizations.account_id_map)
    aws_partition   = module.organizations.aws_partition
  }
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
