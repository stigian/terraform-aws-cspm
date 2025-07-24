variable "project" {
  description = "Name of the project or application. Used for resource naming and tagging."
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "global_tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created. Auto-detected from provider if not specified."
  type        = string
  default     = null
}

variable "deploy_landing_zone" {
  description = <<-EOT
    Whether to deploy the AWS Control Tower Landing Zone.

    When true: Deploys full Control Tower landing zone with guardrails and baseline controls
    When false: Only creates KMS resources, allowing manual Control Tower setup or existing setup

    REQUIREMENT: If true, you must provide management_account_id, log_archive_account_id, and audit_account_id
  EOT
  type        = bool
  default     = true
}

variable "management_account_id" {
  description = "Account ID for the AWS Organization management account."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "Management account ID must be a 12-digit string."
  }
}

variable "log_archive_account_id" {
  description = "Account ID for the Control Tower log archive account."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.log_archive_account_id))
    error_message = "Log archive account ID must be a 12-digit string."
  }
}

variable "audit_account_id" {
  description = "Account ID for the Control Tower audit account."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.audit_account_id))
    error_message = "Audit account ID must be a 12-digit string."
  }
}

variable "self_managed_sso" {
  description = "Whether to use self-managed SSO (accessManagement.enabled = false in manifest). When true, Control Tower will not manage IAM Identity Center resources, allowing you to manage SSO independently. Defaults to true as terraform-aws-cspm provides its own SSO module for lifecycle management."
  type        = bool
  default     = true
}

variable "kms_key_admin_arns" {
  type        = list(string)
  description = "List of IAM ARNs that will be granted KMS key admin permissions."
  default     = []
}
