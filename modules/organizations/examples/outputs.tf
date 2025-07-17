# Output configuration for AWS Organizations Module Example

output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = module.organizations.organization_id
}

output "organizational_unit_ids" {
  description = "Map of OU names to their IDs"
  value       = module.organizations.organizational_unit_ids
}

output "account_id_map" {
  description = "Map of account names to their IDs"
  value       = module.organizations.account_id_map
}

output "account_organizational_units" {
  description = "Map of account IDs to their OU names"
  value       = module.organizations.account_organizational_units
}

# Optional: Display account structure for verification
output "account_structure" {
  description = "Organized view of accounts by OU for verification"
  value = {
    for ou_name, ou_id in module.organizations.organizational_unit_ids : ou_name => {
      ou_id = ou_id
      accounts = {
        for account_id, account_ou in module.organizations.account_organizational_units :
        account_id => var.aws_account_parameters[account_id].name
        if account_ou == ou_name
      }
    }
  }
}

# Display global tags that will be applied to all resources
output "applied_global_tags" {
  description = "Global tags that are applied to all resources"
  value       = var.global_tags
}

# AWS Partition and GovCloud Detection
output "aws_partition" {
  description = "The AWS partition where the organization is running (aws or aws-us-gov)"
  value       = module.organizations.aws_partition
}

output "is_govcloud" {
  description = "Boolean indicating if running in AWS GovCloud (account name changes will be ignored)"
  value       = module.organizations.is_govcloud
}
