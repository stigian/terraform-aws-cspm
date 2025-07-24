# Minimal Quick Start Example
# 
# PREREQUISITE: Create your AWS accounts first using AWS CLI:
#
# aws organizations create-gov-cloud-account --account-name "MyOrg-Management" --email "mgmt@myorg.com"
# aws organizations create-gov-cloud-account --account-name "MyOrg-LogArchive" --email "logs@myorg.com"  
# aws organizations create-gov-cloud-account --account-name "MyOrg-Audit" --email "audit@myorg.com"

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
  required_version = ">= 1.6"
}

provider "aws" {
  region = "us-gov-west-1" # Change to "us-east-1" for commercial AWS
}

# Organizations - define your accounts and OUs
module "organizations" {
  source = "../../modules/organizations"

  project = "myorg"

  aws_account_parameters = {
    "123456789012" = { # Replace with your actual account IDs
      name      = "MyOrg-Management"
      email     = "mgmt@myorg.com"
      ou        = "Root"
      lifecycle = "prod"
      tags      = { AccountType = "management" } # Required for Control Tower
    }
    "234567890123" = {
      name      = "MyOrg-LogArchive"
      email     = "logs@myorg.com"
      ou        = "Security"
      lifecycle = "prod"
      tags      = { AccountType = "log_archive" } # Required for Control Tower
    }
    "345678901234" = {
      name      = "MyOrg-Audit"
      email     = "audit@myorg.com"
      ou        = "Security"
      lifecycle = "prod"
      tags      = { AccountType = "audit" } # Required for Control Tower
    }
  }
}

# Control Tower - deploys landing zone
module "controltower" {
  source = "../../modules/controltower"

  project                = module.organizations.project
  management_account_id  = module.organizations.management_account_id
  log_archive_account_id = module.organizations.log_archive_account_id
  audit_account_id       = module.organizations.audit_account_id

  self_managed_sso = true # Allows separate SSO management
}

# SSO - manages user access
module "sso" {
  source = "../../modules/sso"

  project        = module.organizations.project
  account_id_map = module.organizations.account_id_map

  # Map account names to account types for group assignments
  # Valid account types: management, log_archive, audit, network, shared_services,
  # security_tooling, backup, workload_prod, workload_nonprod, workload_sandbox, deployment, data
  account_role_mapping = {
    "MyOrg-Management" = "management"
    "MyOrg-LogArchive" = "log_archive"
    "MyOrg-Audit"      = "audit"
  }
}
