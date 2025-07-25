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

variable "organizational_units" {
  description = <<-EOT
    Map of Organizational Unit (OU) names to their attributes.
    
    Uses AWS Security Reference Architecture (SRA) standard OUs by default.
    You can extend this by adding additional OUs as needed.
  EOT
  type = map(object({
    lifecycle = optional(string, "prod")
    tags      = optional(map(string), {})
  }))

  # SRA-standard defaults
  default = {
    Security               = { lifecycle = "prod" }
    Infrastructure_Prod    = { lifecycle = "prod" }
    Infrastructure_NonProd = { lifecycle = "nonprod" }
    Workloads_Prod         = { lifecycle = "prod" }
    Workloads_NonProd      = { lifecycle = "nonprod" }
    Sandbox                = { lifecycle = "nonprod" }
    Policy_Staging         = { lifecycle = "nonprod" }
    Suspended              = { lifecycle = "nonprod" }
  }
}

variable "aws_account_parameters" {
  description = <<-EOT
    Map of AWS account parameters to be managed by the module.

    PREREQUISITE: All accounts must already exist (created via AWS Organizations CLI).
    
    CRITICAL: Use EXACT names and emails from CLI account creation.

    Required Control Tower accounts:
    - One account with account_type = "management" 
    - One account with account_type = "log_archive" in Security OU
    - One account with account_type = "audit" in Security OU

    Example:
      {
        "123456789012" = {
          name         = "YourOrg-Management"
          email        = "aws-mgmt@yourorg.com"
          ou           = "Root"
          lifecycle    = "prod"
          account_type = "management"
        }
        "234567890123" = {
          name         = "YourOrg-Security-LogArchive"
          email        = "aws-logs@yourorg.com"
          ou           = "Security"
          lifecycle    = "prod"
          account_type = "log_archive"
        }
        "345678901234" = {
          name         = "YourOrg-Security-Audit"
          email        = "aws-audit@yourorg.com"
          ou           = "Security"
          lifecycle    = "prod"
          account_type = "audit"
        }
      }
  EOT
  type = map(object({
    name         = string
    email        = string
    ou           = string
    lifecycle    = string
    account_type = string
    tags         = optional(map(string), {})
  }))
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
