output "organization_id" {
  description = "AWS Organization ID"
  value       = module.organizations.organization_id
}

output "account_ids" {
  description = "Map of account names to IDs"
  value = {
    management  = module.organizations.management_account_id
    log_archive = module.organizations.log_archive_account_id
    audit       = module.organizations.audit_account_id
  }
}
