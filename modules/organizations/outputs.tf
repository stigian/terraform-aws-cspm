output "organization_id" {
  description = "The AWS Organization ID."
  value       = aws_organizations_organization.this.id
}

output "organizational_unit_ids" {
  description = "Map of OU names to their AWS Organization Unit IDs."
  value       = { for ou_name, ou_resource in aws_organizations_organizational_unit.this : ou_name => ou_resource.id }
}

output "account_id_map" {
  description = "Map of account names to account IDs for use by other modules (e.g., SSO, Control Tower)."
  value = {
    for account_id, account in(
      length(var.all_accounts_all_parameters) > 0 ?
      var.all_accounts_all_parameters :
      var.organizations_account_parameters
    ) : account.name => account_id
  }
}

output "account_organizational_units" {
  description = "Map of account IDs to their OU names."
  value = {
    for account_id, account in(
      length(var.all_accounts_all_parameters) > 0 ?
      var.all_accounts_all_parameters :
      var.organizations_account_parameters
    ) : account_id => account.ou
  }
}

output "project" {
  description = "Project name for use by submodules."
  value       = var.project
}

output "global_tags" {
  description = "Global tags for use by submodules."
  value       = var.global_tags
}

output "aws_partition" {
  description = "The AWS partition (aws or aws-us-gov) where the organization is running."
  value       = data.aws_partition.current.partition
}

output "is_govcloud" {
  description = "Boolean indicating if the organization is running in AWS GovCloud."
  value       = data.aws_partition.current.partition == "aws-us-gov"
}

output "account_resources" {
  description = "Map of account resources (abstracts commercial vs govcloud partition differences)"
  value       = data.aws_partition.current.partition == "aws-us-gov" ? aws_organizations_account.govcloud : aws_organizations_account.commercial
}

output "management_account_id" {
  description = "Account ID for the management account (required for Control Tower)"
  value = try([
    for id, config in(
      length(var.all_accounts_all_parameters) > 0 ?
      var.all_accounts_all_parameters :
      var.organizations_account_parameters
    ) : id
    if config.account_type == "management"
  ][0], null)
}

output "log_archive_account_id" {
  description = "Account ID for the log archive account (required for Control Tower)"
  value = try([
    for id, config in(
      length(var.all_accounts_all_parameters) > 0 ?
      var.all_accounts_all_parameters :
      var.organizations_account_parameters
    ) : id
    if config.account_type == "log_archive"
  ][0], null)
}

output "audit_account_id" {
  description = "Account ID for the audit account (required for Control Tower)"
  value = try([
    for id, config in(
      length(var.all_accounts_all_parameters) > 0 ?
      var.all_accounts_all_parameters :
      var.organizations_account_parameters
    ) : id
    if config.account_type == "audit"
  ][0], null)
}

output "account_role_mapping" {
  description = "Map of account names to their AccountType tags for use by SSO module"
  value = {
    for account_id, config in(
      length(var.all_accounts_all_parameters) > 0 ?
      var.all_accounts_all_parameters :
      var.organizations_account_parameters
    ) : config.name => config.account_type
    if config.account_type != ""
  }
}
