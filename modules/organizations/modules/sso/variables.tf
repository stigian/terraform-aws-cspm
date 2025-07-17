variable "project" {
  description = "Name of the project or application. Used for naming resources. Should be passed from parent organizations module."
  type        = string
}

variable "global_tags" {
  description = "A map of tags to add to all resources. These are merged with any resource-specific tags. Should be passed from parent organizations module."
  type        = map(string)
}



#####

variable "account_id_map" {
  description = <<-EOT
    Mapping of account names to AWS account IDs. Should be passed from parent organizations module.

    Required account types:
      - management: The AWS Organization management account
      - hubandspoke: Network/infrastructure account (also known as VDSS account)
      - log: Log aggregation account
      - audit: Security audit account

    Example:
      {
        management  = "111111111111"
        hubandspoke = "222222222222"
        log         = "333333333333"
        audit       = "444444444444"
      }
  EOT
  type        = map(string)
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


