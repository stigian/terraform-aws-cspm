output "organization_id" {
  description = "The AWS Organization ID"
  value       = module.organizations.organization_id
}

output "account_id_map" {
  description = "Map of account names to account IDs"
  value       = module.organizations.account_id_map
}

output "sso_permission_sets" {
  description = "Map of AWS SSO permission sets"
  value       = module.sso.permission_sets
}

output "sso_identity_store_groups" {
  description = "Map of AWS Identity Store groups"
  value       = module.sso.identity_store_groups
}

output "entra_application" {
  description = "Entra ID application for AWS SSO (if enabled)"
  value       = module.sso.entra_application
  sensitive   = true
}
