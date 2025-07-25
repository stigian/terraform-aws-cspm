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
      contains(keys(yamldecode(file("${path.module}/../../config/sra-account-types.yaml"))), role)
    ])
    error_message = "Account roles must be valid SRA types. See config/sra-account-types.yaml for supported types."
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

variable "auto_detect_control_tower" {
  description = "Whether to automatically detect if Control Tower is managing Identity Center and disable SSO management accordingly."
  type        = bool
  default     = true
}

variable "enable_entra_integration" {
  description = "Whether to enable Microsoft Entra ID integration. Set to false to use only AWS IAM Identity Center without Entra."
  type        = bool
  default     = false
}

variable "azuread_environment" {
  description = "Azure AD environment, either global or usgovernment."
  type        = string
  default     = "usgovernment"

  validation {
    condition     = var.azuread_environment == "global" || var.azuread_environment == "usgovernment"
    error_message = "The azuread_environment variable must be either 'global' or 'usgovernment'."
  }
}

variable "entra_tenant_id" {
  description = "Entra Tenant ID. Required only if enable_entra_integration is true."
  type        = string
  default     = null

  validation {
    condition     = var.enable_entra_integration == false || (var.enable_entra_integration == true && var.entra_tenant_id != null)
    error_message = "entra_tenant_id must be provided when enable_entra_integration is true."
  }
}

variable "saml_notification_emails" {
  description = "List of email addresses to receive SAML certificate expiration notifications. Required only if enable_entra_integration is true."
  type        = list(string)
  default     = []

  validation {
    condition     = var.enable_entra_integration == false || (var.enable_entra_integration == true && length(var.saml_notification_emails) > 0 && alltrue([for email in var.saml_notification_emails : can(regex("^\\S+@\\S+\\.\\S+$", email))]))
    error_message = "saml_notification_emails must be a list of one or more valid email addresses when enable_entra_integration is true."
  }
}

variable "login_url" {
  description = "AWS access portal sign-in URL from IAM Identity Center. Required only if enable_entra_integration is true."
  type        = string
  default     = null

  validation {
    condition     = var.enable_entra_integration == false || (var.enable_entra_integration == true && var.login_url != null)
    error_message = "login_url must be provided when enable_entra_integration is true."
  }
}

variable "redirect_uris" {
  description = "Assertion Consumer Service (ACS) URL(s) from IAM Identity Center. Required only if enable_entra_integration is true."
  type        = list(string)
  default     = []

  validation {
    condition     = var.enable_entra_integration == false || (var.enable_entra_integration == true && length(var.redirect_uris) > 0)
    error_message = "redirect_uris must be provided when enable_entra_integration is true."
  }
}

variable "identifier_uri" {
  description = "Issuer URL from IAM Identity Center. Required only if enable_entra_integration is true."
  type        = string
  default     = null

  validation {
    condition     = var.enable_entra_integration == false || (var.enable_entra_integration == true && var.identifier_uri != null)
    error_message = "identifier_uri must be provided when enable_entra_integration is true."
  }
}

variable "entra_group_admin_object_ids" {
  type        = list(string)
  description = "List of user object IDs for group administrators / owners. Required only if enable_entra_integration is true."
  default     = []

  validation {
    condition     = var.enable_entra_integration == false || (var.enable_entra_integration == true && length(var.entra_group_admin_object_ids) >= 0)
    error_message = "entra_group_admin_object_ids must be provided when enable_entra_integration is true."
  }
}

variable "existing_admin_user_id" {
  description = <<-EOT
    **RECOMMENDED**: User ID of an existing SSO user to grant admin access for Day 1 protection.
    
    If you already have an SSO user (e.g., your personal user), provide the User ID here
    and that user will be automatically added to admin groups for all accounts.
    
    To find your User ID:
    1. Go to AWS Console → IAM Identity Center → Users
    2. Click on your username
    3. Copy the "User ID" field (format: 1234567890-abcd-efgh-ijkl-123456789012)
    
    If this is provided, no new users will be created automatically.
    If this is null/empty, you MUST provide initial_admin_users to prevent Day 1 lockout.
  EOT
  type        = string
  default     = null
}

variable "initial_admin_users" {
  description = <<-EOT
    List of admin users to create in AWS IAM Identity Center.
    
    **REQUIRED** if existing_admin_user_id is not provided (to prevent Day 1 lockout).
    **OPTIONAL** if existing_admin_user_id is provided (for additional users).
    
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

  # Ensure Day 1 protection: either existing user OR new users must be provided
  validation {
    condition     = var.existing_admin_user_id != null || length(var.initial_admin_users) > 0
    error_message = "Either existing_admin_user_id must be provided OR initial_admin_users must contain at least one user to prevent Day 1 lockout."
  }
}
