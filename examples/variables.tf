variable "aws_region" {
  description = "AWS region for the organization. Default is us-gov-west-1."
  type        = string
  default     = "us-gov-west-1"
}

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

variable "aws_organization_id" {
  type        = string
  description = "ID for existing AWS Govcloud Organization. If not provided, the module will create a new organization."
  default     = null
}

# NOTE: aws_account_parameters is now loaded from YAML files via the yaml-transform module
# Account configurations are in config/accounts/*.yaml files
# This provides better version control, readability, and validation
# The yaml-transform module handles data transformation automatically

variable "aws_account_parameters" {
  description = <<-EOT
    Map of AWS account parameters to be managed by the module.
    
    PREREQUISITE: All accounts must already exist (created via AWS Organizations CLI).
    
    Structure:
      {
        "123456789012" = {
          name         = "YourCorp-Management"
          email        = "aws-mgmt@yourcorp.com"
          ou           = "Root"
          lifecycle    = "prod"
          account_type = "management"
        }
      }
    
    See config/account-schema.yaml for detailed field definitions and examples.
    See config/sra-account-types.yaml for valid account_type values.
  EOT
  type = map(object({
    name            = string
    email           = string
    ou              = string
    lifecycle       = string
    account_type    = optional(string, "")
    create_govcloud = optional(bool, false)
  }))

  # Control Tower validation - only when enabled
  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if v.account_type == "management"
    ]) >= 1
    error_message = "Control Tower requires at least one management account (account_type = 'management'). Please add the account_type field to your management account."
  }

  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if v.account_type == "log_archive"
    ]) >= 1
    error_message = "Control Tower requires at least one log archive account (account_type = 'log_archive'). Please add the account_type field to your log archive account."
  }

  validation {
    condition = length([
      for v in values(var.aws_account_parameters) :
      v if v.account_type == "audit"
    ]) >= 1
    error_message = "Control Tower requires at least one audit account (account_type = 'audit'). Please add the account_type field to your audit account."
  }
}

# Legacy variables removed - using standardized variable names
# - variable "tags" replaced with "global_tags" for consistency across modules

# variable "central_bucket_name_prefix" {
#   type        = string
#   description = "Name prefix for S3 bucket in log account where logs are aggregated for all accounts."
#   default     = "org-central-logs"
# }
