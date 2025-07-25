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

variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
  default     = "us-gov-west-1" # Change to "us-east-1" for commercial AWS
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication. Should be configured for your management account."
  type        = string
  default     = "cnscca-gov-mgmt"
}

variable "aws_organization_id" {
  description = "ID for existing AWS Organization. If not provided, the module will create a new organization."
  type        = string
  default     = null
}

# Control Tower Configuration
variable "deploy_landing_zone" {
  description = "Whether to deploy the AWS Control Tower Landing Zone. Set to false if Control Tower is already configured."
  type        = bool
  default     = true
}

variable "self_managed_sso" {
  description = "Whether to use self-managed SSO instead of Control Tower SSO. Recommended for existing Identity Center configurations."
  type        = bool
  default     = true
}

# SSO Configuration
variable "enable_sso_management" {
  description = "Whether to enable SSO management through this module."
  type        = bool
  default     = true
}

variable "auto_detect_control_tower" {
  description = "Whether to automatically detect Control Tower SSO configuration."
  type        = bool
  default     = true
}

variable "existing_admin_user_id" {
  description = <<-EOT
    ID of an existing SSO user to grant admin access.
    
    CRITICAL: Update this with your actual SSO User ID to maintain access.
    You can find this in the AWS SSO console under Users.
    
    Example: "8891c238-90a1-70e8-bf6c-0438721ecc9d"
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.existing_admin_user_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_admin_user_id))
    error_message = "Existing admin user ID must be a valid UUID format."
  }
}

variable "initial_admin_users" {
  description = <<-EOT
    List of additional admin users to create in SSO.
    
    Optional: Only needed if you want to create new admin users.
  EOT
  type = list(object({
    user_name    = string
    display_name = string
    email        = string
    given_name   = string
    family_name  = string
    admin_level  = optional(string, "organization")
  }))
  default = []
}
