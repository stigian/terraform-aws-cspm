variable "project" {
  description = "Name of the project or application. Used for naming resources."
  type        = string
}

variable "global_tags" {
  description = "A map of tags to add to all resources. These are merged with any resource-specific tags."
  type        = map(string)
}

#####

variable "account_id_map" {
  description = <<-EOT
    Mapping of account names to AWS account IDs.

    Required account types should include:
      - management: The AWS Organization management account
      - network: Network/connectivity account (for Transit Gateway, etc.)
      - log_archive: Log aggregation and archive account
      - audit: Security audit account

    Example:
      {
        "Management Account" = "111111111111"
        "Network Account"    = "222222222222"
        "Log Archive"        = "333333333333"
        "Security Audit"     = "444444444444"
      }
  EOT
  type        = map(string)
}

variable "account_role_mapping" {
  description = <<-EOT
    Mapping of account names to their AWS SRA account types for SSO group assignments.
    
    Each key should match an account name from account_id_map.
    Each value must be one of the standard AWS SRA account types:
    
    **Core Foundation Accounts (Required):**
    - management: Organization management account (stays at org root)
    - log_archive: Centralized logging and long-term log storage
    - audit: Security audit and compliance account
    -
    **Connectivity & Network Accounts:**
    - network: Central network connectivity (Transit Gateway, Direct Connect, etc.)
    - shared_services: Shared infrastructure services (DNS, monitoring, etc.)
    
    **Security Accounts:**
    - security_tooling: Security tools and SIEM (often combined with audit)
    - backup: Centralized backup and disaster recovery
    
    **Workload Accounts:**
    - workload_prod: Production workloads
    - workload_nonprod: Non-production workloads (dev, test, staging)
    - workload_sandbox: Experimental and sandbox environments
    
    **Future Account Types (for reference):**
    - deployment: CI/CD and deployment tools
    - data: Data lakes, analytics, and big data workloads
    
    Example:
      {
        "MyOrg Management"     = "management"
        "Production Network"   = "network" 
        "Security Log Archive" = "log_archive"
        "Compliance Audit"     = "audit"
        "ACME-prod-workload"   = "workload_prod"
        "ACME-dev-workload"    = "workload_nonprod"
      }
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for role in values(var.account_role_mapping) : contains([
        # Core Foundation (Required by SRA)
        "management",
        "log_archive",
        "audit",
        # Connectivity & Network
        "network",
        "shared_services",
        # Security
        "security_tooling",
        "backup",
        # Workloads
        "workload_prod",
        "workload_nonprod",
        "workload_sandbox",
        # Future expansion
        "deployment",
        "data"
      ], role)
    ])
    error_message = "Account roles must be valid AWS SRA account types. See variable description for supported types."
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
