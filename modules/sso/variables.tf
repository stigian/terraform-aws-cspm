variable "project" {
  description = "Name of the project or application. Used for resource naming and tagging."
  type        = string
  default     = "CnScca"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project))
    error_message = "Project name must contain only letters, numbers, and hyphens."
  }
}

variable "global_tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default = {
    ManagedBy = "opentofu"
  }
}

#####

variable "account_id_map" {
  description = <<-EOT
    Mapping of account names to AWS account IDs.

    CONTROL TOWER REQUIREMENTS (if using Control Tower):
    The following account types are MANDATORY and must match your Organizations module:
      - management: The AWS Organization management account (AccountType = "management")
      - log_archive: Log aggregation and archive account (AccountType = "log_archive")
      - audit: Security audit account (AccountType = "audit")

    Additional recommended account types:
      - network: Network/connectivity account (for Transit Gateway, etc.)
      - shared_services: Shared infrastructure services

    Example:
      {
        "YourCorp-Management"       = "123456789012"   # REQUIRED for Control Tower
        "YourCorp-Security-Logs"    = "234567890123"   # REQUIRED for Control Tower
        "YourCorp-Security-Audit"   = "345678901234"   # REQUIRED for Control Tower
        "YourCorp-Network-Hub"      = "456789012345"   # Optional
        "YourCorp-Workload-Prod1"   = "567890123456"   # Optional
      }

    NOTE: Account names here must match the 'name' field in your aws_account_parameters
  EOT
  type        = map(string)
}

variable "account_role_mapping" {
  description = <<-EOT
    Mapping of account names to their AWS SRA account types for SSO group assignments.

    Each key should match an account name from account_id_map.
    Each value must be one of the standard AWS SRA account types.

    **CONTROL TOWER REQUIRED ACCOUNTS:**
    - management: Organization management account (REQUIRED - AccountType = "management")
    - log_archive: Centralized logging and log storage (REQUIRED - AccountType = "log_archive")
    - audit: Security audit and compliance (REQUIRED - AccountType = "audit")

    **SRA-Recommended Security OU Accounts:**
    - security_tooling: Security tools, SIEM, and scanning infrastructure

    **SRA-Recommended Infrastructure OU Accounts:**
    - network: Central network connectivity (Transit Gateway, Direct Connect, etc.)
    - shared_services: Shared infrastructure services (DNS, monitoring, etc.)

    **SRA-Recommended Workloads OU Accounts:**
    - workload: Application workload accounts (organize by environment or application per SRA)

    Example (showing Control Tower + SRA recommended structure):
      {
        "YourCorp-Management"           = "management"        # REQUIRED - Root OU
        "YourCorp-Security-LogArchive"  = "log_archive"       # REQUIRED - Security OU
        "YourCorp-Security-Audit"       = "audit"            # REQUIRED - Security OU
        "YourCorp-Security-Tooling"     = "security_tooling" # Security OU
        "YourCorp-Infrastructure-Network" = "network"        # Infrastructure OU
        "YourCorp-Infrastructure-Shared"  = "shared_services" # Infrastructure OU
        "YourCorp-Workload-App1-Prod"   = "workload"         # Workloads OU
      }

    NOTE: Account names must match exactly with account_id_map keys
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for role in values(var.account_role_mapping) :
      contains([
        "management",
        "log_archive",
        "audit",
        "security_tooling",
        "network",
        "shared_services",
        "workload"
      ], role)
    ])
    error_message = "Account roles must be valid SRA types: management, log_archive, audit, security_tooling, network, shared_services, workload"
  }
}

#####

variable "enable_sso_management" {
  description = <<-EOT
    Whether to enable management of AWS IAM Identity Center resources.

    Set to false if:
    - Control Tower is managing Identity Center
    - Identity Center is managed elsewhere
    - You only want Entra ID groups without AWS SSO integration

    When false, only Entra ID resources (if enabled) will be created.

    Note: The module will automatically detect if Control Tower is managing
    Identity Center and adjust accordingly.
  EOT
  type        = bool
  default     = true
}

# TODO: remove this in favor of just using var.enable_sso_management
variable "auto_detect_control_tower" {
  description = "Whether to automatically detect if Control Tower is managing Identity Center and disable SSO management accordingly."
  type        = bool
  default     = true
}

# TODO: remove this, assume the caller will not have deployed IAM Identity Center yet and so no user will exist

variable "initial_admin_users" {
  description = <<-EOT
    List of admin users to create in AWS IAM Identity Center (optional).

    Each user object should contain:
    - user_name: Unique username for SSO login (e.g., "john.doe" or "admin")
    - display_name: Human-readable display name (e.g., "John Doe")
    - email: Primary email address for the user
    - given_name: First name
    - family_name: Last name
    - admin_level: Level of admin access ("full" or "security")
      - "full": Gets aws_admin group (AdministratorAccess to all accounts)
      - "security": Gets aws_cyber_sec_eng and aws_sec_auditor groups (security-focused access)

    Example:
      [
        {
          user_name    = "john.doe"
          display_name = "John Doe"
          email        = "john.doe@your-company.com"
          given_name   = "John"
          family_name  = "Doe"
          admin_level  = "full"
        }
      ]
  EOT
  type = list(object({
    user_name    = string
    display_name = string
    email        = string
    given_name   = string
    family_name  = string
    admin_level  = string
  }))
  default = []

  validation {
    condition = alltrue([
      for user in var.initial_admin_users : contains(["full", "security"], user.admin_level)
    ])
    error_message = "admin_level must be either 'full' or 'security'."
  }

  validation {
    condition = alltrue([
      for user in var.initial_admin_users : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", user.email))
    ])
    error_message = "All email addresses must be valid email format."
  }
}
