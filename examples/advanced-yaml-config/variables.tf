variable "aws_region" {
  description = "AWS region for the organization. Default is us-gov-west-1."
  type        = string
  default     = "us-gov-west-1"
}

variable "aws_organization_id" {
  description = "ID for existing AWS Organization. If not provided, the module will create a new organization."
  type        = string
  default     = null
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
    ManagedBy  = "opentofu"
    Owner      = "stigian"
    Repository = "https://github.com/stigian/terraform-aws-cspm"
  }
}

variable "deploy_landing_zone" {
  description = "Whether to deploy a new Control Tower Landing Zone. Set to false if Control Tower is already deployed."
  type        = bool
  default     = true
}

variable "self_managed_sso" {
  description = "Whether to disable Control Tower's SSO management (enables separate SSO module management)."
  type        = bool
  default     = true
}
