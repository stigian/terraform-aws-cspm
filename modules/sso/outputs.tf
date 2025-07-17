output "identity_store_groups" {
  description = "Map of AWS Identity Store groups created by this module."
  value       = local.sso_management_enabled ? aws_identitystore_group.this : {}
}

output "permission_sets" {
  description = "Map of AWS SSO permission sets created by this module."
  value       = local.sso_management_enabled ? aws_ssoadmin_permission_set.this : {}
}

output "entra_groups" {
  description = "Map of Entra ID groups created by this module."
  value       = var.enable_entra_integration ? aws_identitystore_group.this : {}
}

output "entra_application" {
  description = "The Entra ID application for AWS SSO integration."
  value       = var.enable_entra_integration && length(azuread_application.aws_sso) > 0 ? azuread_application.aws_sso[0] : null
}

output "control_tower_detected" {
  description = "Boolean indicating if Control Tower was detected managing the organization."
  value       = var.auto_detect_control_tower ? local.control_tower_detected : null
}

output "sso_management_enabled" {
  description = "Boolean indicating if SSO management is enabled (may be disabled due to Control Tower detection)."
  value       = local.sso_management_enabled
}

output "account_assignments" {
  description = "Map of account assignments created by this module."
  value       = var.enable_sso_management ? aws_ssoadmin_account_assignment.this : {}
}
