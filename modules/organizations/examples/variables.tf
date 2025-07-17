# Variables for AWS Organizations Module Example

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-gov-west-1"
}

variable "project" {
  description = "Name of the project or application. Used for naming resources."
  type        = string
  default     = "my-project"
}

variable "global_tags" {
  description = "A map of tags to add to all resources. These are merged with any resource-specific tags."
  type        = map(string)
  default = {
    Project    = "my-project"
    Owner      = "platform-team"
    Repository = "https://github.com/organization/terraform-aws-cspm"
    Terraform  = "true"
  }
}

variable "organizational_units" {
  description = <<-EOT
    Map of Organizational Unit (OU) names to their attributes following AWS SRA structure.
    
    Each OU represents a logical grouping of accounts based on their function and security requirements.
  EOT
  type = map(object({
    lifecycle = string
    tags      = optional(map(string), {})
  }))
  default = {
    # Security OU - Houses accounts for security, compliance, and logging
    Security = {
      lifecycle = "prod"
      tags = {
        Function = "Security"
        Purpose  = "Security and compliance accounts"
      }
    }

    # Infrastructure Production OU - Production infrastructure services
    Infrastructure_Prod = {
      lifecycle = "prod"
      tags = {
        Function = "Infrastructure"
        Purpose  = "Production infrastructure services"
      }
    }

    # Infrastructure Test OU - Non-production infrastructure
    Infrastructure_Test = {
      lifecycle = "nonprod"
      tags = {
        Function = "Infrastructure"
        Purpose  = "Development and testing infrastructure"
      }
    }

    # Workloads Production OU - Production application workloads
    Workloads_Prod = {
      lifecycle = "prod"
      tags = {
        Function = "Workloads"
        Purpose  = "Production application workloads"
      }
    }

    # Workloads Test OU - Development and testing workloads
    Workloads_Test = {
      lifecycle = "nonprod"
      tags = {
        Function = "Workloads"
        Purpose  = "Development and testing workloads"
      }
    }

    # Sandbox OU - Experimental and proof-of-concept accounts
    Sandbox = {
      lifecycle = "nonprod"
      tags = {
        Function = "Sandbox"
        Purpose  = "Experimental and POC accounts"
      }
    }

    # Policy Staging OU - For testing organization policies before deployment
    Policy_Staging = {
      lifecycle = "nonprod"
      tags = {
        Function = "Policy"
        Purpose  = "Organization policy testing"
      }
    }

    # Suspended OU - For suspended or decommissioned accounts
    Suspended = {
      lifecycle = "nonprod"
      tags = {
        Function = "Suspended"
        Purpose  = "Suspended or decommissioned accounts"
      }
    }
  }
}

variable "aws_account_parameters" {
  description = <<-EOT
    Map of AWS account parameters following AWS SRA account taxonomy.
    
    **IMPORTANT**: 
    - All accounts must already exist - this module does not create accounts
    - Account IDs must be exactly 12 digits
    - Account names must be unique
    - Email addresses must match actual account email addresses
    - Management account should use ou = "Root"
    
    Example account types following AWS SRA:
    - Management: Organization management account
    - Log Archive: Centralized logging account  
    - Audit: Security audit and compliance account
    - Network: Central network connectivity account
    - Shared Services: Shared infrastructure services
    - Security Tooling: Security tools and SIEM
    - Backup: Centralized backup and recovery
    - Workload accounts: Application workloads (prod/nonprod/sandbox)
  EOT
  type = map(object({
    email           = string
    lifecycle       = string
    name            = string
    ou              = string
    tags            = optional(map(string), {})
    create_govcloud = optional(bool, false)
  }))

  # Example configuration - customize with your actual account details
  default = {
    "111111111111" = {
      email           = "aws-management@organization.com"
      lifecycle       = "prod"
      name            = "Management Account"
      ou              = "Root" # Management account stays at organization root
      create_govcloud = false
      tags = {
        AccountType = "management"
      }
    }

    "222222222222" = {
      email           = "aws-log-archive@organization.com"
      lifecycle       = "prod"
      name            = "Security Log Archive"
      ou              = "Security"
      create_govcloud = true
      tags = {
        AccountType = "log_archive"
      }
    }

    "333333333333" = {
      email           = "aws-audit@organization.com"
      lifecycle       = "prod"
      name            = "Security Audit"
      ou              = "Security"
      create_govcloud = true
      tags = {
        AccountType = "audit"
      }
    }

    "444444444444" = {
      email           = "aws-network@organization.com"
      lifecycle       = "prod"
      name            = "Infrastructure Network"
      ou              = "Infrastructure_Prod"
      create_govcloud = true
      tags = {
        AccountType = "network"
      }
    }

    "555555555555" = {
      email           = "aws-shared-services@organization.com"
      lifecycle       = "prod"
      name            = "Infrastructure Shared"
      ou              = "Infrastructure_Prod"
      create_govcloud = true
      tags = {
        AccountType = "shared_services"
      }
    }

    "666666666666" = {
      email           = "aws-security-tools@organization.com"
      lifecycle       = "prod"
      name            = "Security Tooling"
      ou              = "Security"
      create_govcloud = true
      tags = {
        AccountType = "security_tooling"
      }
    }

    "777777777777" = {
      email           = "aws-workload-prod@organization.com"
      lifecycle       = "prod"
      name            = "Workload Production"
      ou              = "Workloads_Prod"
      create_govcloud = true
      tags = {
        AccountType = "workload_prod"
      }
    }

    "888888888888" = {
      email           = "aws-workload-dev@organization.com"
      lifecycle       = "nonprod"
      name            = "Workload Development"
      ou              = "Workloads_Test"
      create_govcloud = false
      tags = {
        AccountType = "workload_nonprod"
      }
    }

    "999999999999" = {
      email           = "aws-sandbox@organization.com"
      lifecycle       = "nonprod"
      name            = "Workload Sandbox"
      ou              = "Sandbox"
      create_govcloud = false
      tags = {
        AccountType = "workload_sandbox"
      }
    }
  }
}
