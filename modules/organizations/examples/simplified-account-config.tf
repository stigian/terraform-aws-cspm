# Example: Simplified Account Configuration
# Using the new streamlined aws_account_parameters format

module "organizations" {
  source = "../"

  project = "my-organization"

  global_tags = {
    Environment = "production"
    ManagedBy   = "opentofu"
  }

  # Simplified account configuration - cleaner and more maintainable
  aws_account_parameters = {
    # Management account - required for Control Tower
    "123456789012" = {
      name         = "MyOrg-Management"
      email        = "aws-management@myorg.com"
      ou           = "Root"
      lifecycle    = "prod"
      account_type = "management" # Optional, only needed if using Control Tower
    }

    # Security accounts - required for Control Tower
    "234567890123" = {
      name         = "MyOrg-LogArchive"
      email        = "aws-logs@myorg.com"
      ou           = "Security"
      lifecycle    = "prod"
      account_type = "log_archive"
    }

    "345678901234" = {
      name         = "MyOrg-Audit"
      email        = "aws-audit@myorg.com"
      ou           = "Security"
      lifecycle    = "prod"
      account_type = "audit"
    }

    # Optional SRA-recommended accounts
    "456789012345" = {
      name         = "MyOrg-Network"
      email        = "aws-network@myorg.com"
      ou           = "Infrastructure_Prod"
      lifecycle    = "prod"
      account_type = "network"
    }

    "567890123456" = {
      name         = "MyOrg-App1-Prod"
      email        = "aws-app1-prod@myorg.com"
      ou           = "Workloads_Prod"
      lifecycle    = "prod"
      account_type = "workload"
    }

    # Non-production workload (account_type is optional)
    "678901234567" = {
      name      = "MyOrg-App1-Dev"
      email     = "aws-app1-dev@myorg.com"
      ou        = "Workloads_NonProd"
      lifecycle = "nonprod"
      # account_type omitted for simple workloads
    }
  }

  organizational_units = {
    "Security" = {
      lifecycle = "prod"
    }
    "Infrastructure_Prod" = {
      lifecycle = "prod"
    }
    "Workloads_Prod" = {
      lifecycle = "prod"
    }
    "Workloads_NonProd" = {
      lifecycle = "nonprod"
    }
  }

  control_tower_enabled = true
}
