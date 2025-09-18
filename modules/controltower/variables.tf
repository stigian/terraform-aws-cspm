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

variable "additional_kms_key_admin_arns" {
  description = <<-EOT
    Optional list of additional IAM ARNs that will be granted KMS key administrative permissions.

    Use this to grant KMS admin access to specific users, roles, or external accounts beyond the default admins:
    - Current Terraform caller
    - SSO Administrator roles
    - Project-specific admin roles

    Example: ["arn:aws-us-gov:iam::123456789012:user/admin", "arn:aws-us-gov:iam::123456789012:role/SecurityTeam"]
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.additional_kms_key_admin_arns : can(regex("^arn:aws(-us-gov)?:iam::[0-9]{12}:(user|role|root)/.+", arn))
    ])
    error_message = "All ARNs must be valid IAM ARNs in the format: arn:aws-us-gov:iam::account-id:user/username or arn:aws-us-gov:iam::account-id:role/rolename (or arn:aws: for commercial)"
  }
}

variable "governed_regions" {
  type        = list(string)
  description = "List of AWS regions to be governed by Control Tower."
  default     = ["us-gov-west-1", "us-gov-east-1"]
}