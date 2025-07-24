output "aws_account_parameters" {
  description = "Processed account parameters for organizations module"
  value       = local.aws_account_parameters
}

output "organizational_units" {
  description = "Processed organizational units for organizations module"
  value       = local.organizational_units
}

output "sso_groups" {
  description = "SSO groups configuration"
  value       = local.sso_groups
}

output "sso_account_assignments" {
  description = "SSO account assignments configuration"
  value       = local.sso_account_assignments
}

output "project" {
  description = "Project name for use by other modules"
  value       = var.project
}

output "global_tags" {
  description = "Global tags for use by other modules"
  value       = var.global_tags
}
