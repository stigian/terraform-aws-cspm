output "account_assignments" {
  description = "Map of account assignments created by this module."
  value       = var.use_self_managed_sso ? aws_ssoadmin_account_assignment.this : {}
}

output "sra_account_types" {
  description = "Map of SRA account types with their configurations."
  value       = local.sra_account_types
}
