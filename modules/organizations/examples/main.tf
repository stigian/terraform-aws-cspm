# AWS Organizations Module Example
#
# This example demonstrates how to use the AWS Organizations module to create
# and manage an AWS Organization with Organizational Units (OUs) following
# AWS Security Reference Architecture (SRA) best practices.

# Configure the AWS Provider for the management account
provider "aws" {
  alias  = "management"
  region = var.aws_region

  # Use default credentials or configure as needed
  # profile = "management-account-profile"
}

# AWS Organizations Module
module "organizations" {
  source = "../"

  # Pass through the management provider
  providers = {
    aws.management = aws.management
  }

  # Basic Configuration
  project = var.project

  # Global tags applied to all resources
  global_tags = var.global_tags

  # Optional: Import existing organization by ID
  # aws_organization_id = "o-1234567890"

  # Organizational Units following AWS SRA structure
  organizational_units = var.organizational_units

  # AWS Account Parameters
  # Note: All accounts must already exist - this module does not create accounts
  aws_account_parameters = var.aws_account_parameters
}

# Example output usage
output "organization_info" {
  description = "AWS Organization information"
  value = {
    organization_id = module.organizations.organization_id
    ou_ids          = module.organizations.organizational_unit_ids
  }
}

output "account_mapping" {
  description = "Account name to ID mapping for use with other modules"
  value       = module.organizations.account_id_map
  sensitive   = false
}

# Example mapping from account names to SRA account role types
# This mapping can be used by other modules (e.g., SSO, Control Tower)
locals {
  account_name_to_role_mapping = {
    "Management Account"        = "management"
    "Security Log Archive"      = "log_archive"
    "Security Audit"            = "audit"
    "Infrastructure Network"    = "network"
    "Infrastructure Shared"     = "shared_services"
    "Security Tooling"          = "security_tooling"
    "Infrastructure Backup"     = "backup"
    "Workload Production"       = "workload_prod"
    "Workload Development"      = "workload_nonprod"
    "Workload Sandbox"          = "workload_sandbox"
    "Infrastructure Deployment" = "deployment"
    "Workload Data Analytics"   = "data"
  }
}
