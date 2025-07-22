variable "project" {
  description = "Name of the project or application. Used for naming resources."
  type        = string
  default     = "demo"
}

variable "global_tags" {
  description = "A map of tags to add to all resources. These are merged with any resource-specific tags."
  type        = map(string)
  default = {
    Project    = "demo"
    Owner      = "stigian"
    Repository = "https://github.com/stigian/terraform-aws-cspm"
  }
}

variable "aws_organization_id" {
  description = "ID for existing AWS Govcloud Organization. If not provided, the module will create a new organization."
  type        = string
  default     = null
}

variable "organizational_units" {
  description = <<-EOT
    Map of Organizational Unit (OU) names to their attributes.

    Example:
      {
        Security = {
          lifecycle = "prod"
          tags      = { Owner = "SecurityTeam" }
        }
        Workloads_Prod = {
          lifecycle = "prod"
          tags      = {}
        }
      }

    - The key is the OU name.
    - The value is an object with:
        - lifecycle: (string) The lifecycle tag for the OU (e.g., "prod", "nonprod").
        - tags:      (optional map) Additional tags for the OU.
  EOT
  type = map(object({
    lifecycle = string
    tags      = optional(map(string), {})
  }))
  default = {
    Security = {
      lifecycle = "prod"
      tags      = {}
    }
    Infrastructure_Prod = {
      lifecycle = "prod"
      tags      = {}
    }
    Infrastructure_Test = {
      lifecycle = "nonprod"
      tags      = {}
    }
    Workloads_Prod = {
      lifecycle = "prod"
      tags      = {}
    }
    Workloads_Test = {
      lifecycle = "nonprod"
      tags      = {}
    }
    Sandbox = {
      lifecycle = "nonprod"
      tags      = {}
    }
    Policy_Staging = {
      lifecycle = "nonprod"
      tags      = {}
    }
    Suspended = {
      lifecycle = "nonprod"
      tags      = {}
    }
  }

  validation {
    condition     = alltrue([for k in keys(var.organizational_units) : length(trimspace(k)) > 0])
    error_message = "OU names (keys) must not be empty."
  }

  validation {
    condition     = alltrue([for v in values(var.organizational_units) : length(trimspace(v.lifecycle)) > 0])
    error_message = "Each OU must have a non-empty 'lifecycle' value."
  }

  validation {
    condition     = alltrue([for v in values(var.organizational_units) : contains(["prod", "nonprod", "test", "dev", "staging"], v.lifecycle)])
    error_message = "Each OU 'lifecycle' must be one of: 'prod', 'nonprod', 'test', 'dev', or 'staging'."
  }
}

variable "aws_account_parameters" {
  description = <<-EOT
    Map of AWS account parameters to be managed by the module.
    
    PREREQUISITE: All accounts must already exist (created via AWS Organizations CLI).
    
    CONTROL TOWER REQUIREMENTS (MINIMUM 3 ACCOUNTS):
    If using Control Tower, these accounts are MANDATORY with specific configurations:

    1. MANAGEMENT ACCOUNT (required):
      - Must have: tags = { AccountType = "management" }
      - Must be in: ou = "Root"
      - Only one allowed

    2. LOG ARCHIVE ACCOUNT (required):
      - Must have: tags = { AccountType = "log_archive" }
      - Must be in: ou = "Security"
      - Only one allowed

    3. AUDIT ACCOUNT (required):
      - Must have: tags = { AccountType = "audit" }
      - Must be in: ou = "Security"
      - Only one allowed

    REQUIRED AccountType tag values for Control Tower:
    - "management" - AWS Organization management account
    - "log_archive" - Log aggregation account
    - "audit" - Security audit account

    Optional AccountType tag values:
    - "workload" - Application workload accounts
    - "network" - Network hub/transit gateway accounts
    - "shared_services" - Shared infrastructure accounts

    Example (showing MINIMUM required accounts):
      {
        # REQUIRED: Management Account
        "123456789012" = {
          name      = "YourCorp-Management"
          email     = "aws-mgmt@yourcorp.com"
          ou        = "Root"                           # REQUIRED: Must be Root
          lifecycle = "prod"
          tags      = { AccountType = "management" }   # REQUIRED: Must be "management"
        }
        # REQUIRED: Log Archive Account
        "234567890123" = {
          name      = "YourCorp-Security-LogArchive"
          email     = "aws-logs@yourcorp.com"
          ou        = "Security"                       # REQUIRED: Must be Security
          lifecycle = "prod"
          tags      = { AccountType = "log_archive" }  # REQUIRED: Must be "log_archive"
        }
        # REQUIRED: Audit Account
        "345678901234" = {
          name      = "YourCorp-Security-Audit"
          email     = "aws-audit@yourcorp.com"
          ou        = "Security"                       # REQUIRED: Must be Security
          lifecycle = "prod"
          tags      = { AccountType = "audit" }        # REQUIRED: Must be "audit"
        }
        # OPTIONAL: Additional accounts
        "456789012345" = {
          name      = "YourCorp-Workload-Prod1"
          email     = "aws-prod-app1@yourcorp.com"
          ou        = "Workloads_Prod"
          lifecycle = "prod"
          tags      = { AccountType = "workload", Environment = "Production" }
        }
      }

    Available OUs (defined in organizational_units variable):
    - "Root" - For management account ONLY
    - "Security" - For log_archive and audit accounts (REQUIRED)
    - "Infrastructure_Prod" - For production infrastructure
    - "Infrastructure_Test" - For test infrastructure
    - "Workloads_Prod" - For production workloads
    - "Workloads_Test" - For test workloads
    - "Sandbox" - For experimental/sandbox accounts
    - "Policy_Staging" - For policy testing
    - "Suspended" - For suspended accounts

    Parameters for each account:
    - name: Display name for the account (must match existing account name)
    - email: Primary email address (must match existing account email)
    - ou: Organizational Unit name (must match an OU from organizational_units)
    - lifecycle: Environment lifecycle ("prod" or "nonprod")
    - tags: Map of additional tags (AccountType tag REQUIRED for Control Tower)
    - "Policy_Staging" - For policy testing
    - "Suspended" - For suspended accounts

    Notes:
    - Use EXACT names and emails from CLI account creation commands
    - 'ou' must match one of the organizational_units or be "Root"
    - 'lifecycle' must match the lifecycle of the target OU
    - Account IDs are the 12-digit AWS account numbers returned from CLI
  EOT
  type = map(object({
    name            = string
    email           = string
    ou              = string
    lifecycle       = string
    tags            = optional(map(string), {})
    create_govcloud = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for k in keys(var.aws_account_parameters) : can(regex("^[0-9]{12}$", k))])
    error_message = "All account IDs (keys) must be exactly 12 digits."
  }

  validation {
    condition     = alltrue([for v in values(var.aws_account_parameters) : length(trimspace(v.email)) > 0 && can(regex("^\\S+@\\S+\\.\\S+$", v.email))])
    error_message = "Each account must have a valid email address."
  }

  validation {
    condition     = alltrue([for v in values(var.aws_account_parameters) : length(trimspace(v.name)) > 0])
    error_message = "Each account must have a non-empty 'name'."
  }

  validation {
    condition     = length(values(var.aws_account_parameters)[*].name) == length(distinct(values(var.aws_account_parameters)[*].name))
    error_message = "Account names must be unique. Duplicate account names found."
  }

  validation {
    condition = alltrue([
      for v in values(var.aws_account_parameters) :
      contains(["prod", "nonprod", "test", "dev", "staging"], v.lifecycle)
    ])
    error_message = "Each account 'lifecycle' must be one of: 'prod', 'nonprod', 'test', 'dev', or 'staging'."
  }

  validation {
    condition = alltrue([
      for v in values(var.aws_account_parameters) :
      v.ou == "Root" || contains(keys(var.organizational_units), v.ou)
    ])
    error_message = "Each account 'ou' must reference an existing Organizational Unit defined in 'organizational_units' or be 'Root' for the management account."
  }

  # Control Tower requirement: Management account must be in Root OU
  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "management" && v.ou != "Root"
    ]) == 0
    error_message = "Control Tower requires the management account (AccountType = 'management') to be in the 'Root' OU."
  }

  # Control Tower requirement: Log Archive account must be in Security OU
  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "log_archive" && v.ou != "Security"
    ]) == 0
    error_message = "Control Tower requires the log archive account (AccountType = 'log_archive') to be in the 'Security' OU."
  }

  # Control Tower requirement: Audit account must be in Security OU
  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "audit" && v.ou != "Security"
    ]) == 0
    error_message = "Control Tower requires the audit account (AccountType = 'audit') to be in the 'Security' OU."
  }

  # Control Tower requirement: Must have exactly one of each required account type
  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "management"
    ]) <= 1
    error_message = "Control Tower allows only one management account (AccountType = 'management')."
  }

  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "log_archive"
    ]) <= 1
    error_message = "Control Tower allows only one log archive account (AccountType = 'log_archive')."
  }

  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "audit"
    ]) <= 1
    error_message = "Control Tower allows only one audit account (AccountType = 'audit')."
  }

  # Control Tower requirement: Must have at least one of each required account type
  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "management"
    ]) >= 1
    error_message = "Control Tower requires at least one management account (AccountType = 'management'). Please add the AccountType tag to your management account."
  }

  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "log_archive"
    ]) >= 1
    error_message = "Control Tower requires at least one log archive account (AccountType = 'log_archive'). Please add the AccountType tag to your log archive account."
  }

  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if lookup(v.tags, "AccountType", "") == "audit"
    ]) >= 1
    error_message = "Control Tower requires at least one audit account (AccountType = 'audit'). Please add the AccountType tag to your audit account."
  }
}
