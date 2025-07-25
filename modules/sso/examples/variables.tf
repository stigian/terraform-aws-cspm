variable "project" {
  description = "Name of the project or application. Used for naming resources."
  type        = string
  default     = "CnScca"
}

variable "aws_organization_id" {
  description = "ID for existing AWS Organization. If not provided, the module will create a new organization."
  type        = string
  default     = null
}

variable "organizational_units" {
  description = "Map of Organizational Unit (OU) names to their attributes."
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
    Workloads_Prod = {
      lifecycle = "prod"
      tags      = {}
    }
    Sandbox = {
      lifecycle = "nonprod"
      tags      = {}
    }
  }
}

variable "aws_account_parameters" {
  description = "Map of AWS account parameters to be managed by the module."
  type = map(object({
    email     = string
    lifecycle = string
    name      = string
    ou        = string
    tags      = optional(map(string), {})
  }))
}

variable "global_tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    ManagedBy = "opentofu"
    Owner     = "terraform"
  }
}

# SSO Configuration Variables
variable "enable_sso_management" {
  description = "Whether to enable management of AWS IAM Identity Center resources."
  type        = bool
  default     = true
}

variable "auto_detect_control_tower" {
  description = "Whether to automatically detect if Control Tower is managing Identity Center."
  type        = bool
  default     = true
}

# Entra ID Integration Variables
variable "enable_entra_integration" {
  description = "Whether to enable Microsoft Entra ID integration."
  type        = bool
  default     = false
}

variable "azuread_environment" {
  description = "Azure AD environment, either global or usgovernment."
  type        = string
  default     = "usgovernment"
}

variable "entra_tenant_id" {
  description = "Entra Tenant ID. Required only if enable_entra_integration is true."
  type        = string
  default     = null
}

variable "saml_notification_emails" {
  description = "List of email addresses to receive SAML certificate expiration notifications."
  type        = list(string)
  default     = []
}

variable "login_url" {
  description = "AWS access portal sign-in URL from IAM Identity Center."
  type        = string
  default     = null
}

variable "redirect_uris" {
  description = "Assertion Consumer Service (ACS) URL(s) from IAM Identity Center."
  type        = list(string)
  default     = []
}

variable "identifier_uri" {
  description = "Issuer URL from IAM Identity Center."
  type        = string
  default     = null
}

variable "entra_group_admin_object_ids" {
  description = "List of user object IDs for group administrators / owners."
  type        = list(string)
  default     = []
}
