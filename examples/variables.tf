# Essential variables for the CSPM deployment example

variable "project" {
  description = "Name of the project or application. Used for resource naming and tagging."
  type        = string
  default     = "example-cspm"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project))
    error_message = "Project name must contain only letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for the organization deployment."
  type        = string
  default     = "us-gov-west-1"
}

variable "aws_organization_id" {
  description = "ID for existing AWS Organization. Required for importing existing organization."
  type        = string
}

variable "org_exec_role_name" {
  description = "Name of the IAM role to assume in member accounts for organization-wide operations."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "global_tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default = {
    ManagedBy   = "opentofu"
    Environment = "example"
  }
}

variable "inputs_directory" {
  description = "Path to the directory containing YAML configuration files."
  type        = string
  default     = "./inputs"
}

variable "enable_locals_validation" {
  description = "Whether to enable validation checks on local variables."
  type        = bool
  default     = true
}

variable "control_tower_enabled" {
  description = "Whether Control Tower is enabled for this organization."
  type        = bool
  default     = true
}

variable "governed_regions" {
  description = "List of AWS regions to be governed by Control Tower."
  type        = list(string)
  default     = ["us-gov-west-1", "us-gov-east-1"]
}

# GuardDuty Configuration
variable "enable_s3_protection" {
  description = "Enable GuardDuty S3 protection."
  type        = bool
  default     = true
}

variable "enable_runtime_monitoring" {
  description = "Enable GuardDuty runtime monitoring."
  type        = bool
  default     = true
}

variable "enable_malware_protection_ec2" {
  description = "Enable GuardDuty malware protection for EC2."
  type        = bool
  default     = false
}

variable "enable_lambda_protection" {
  description = "Enable GuardDuty Lambda protection."
  type        = bool
  default     = false
}

variable "enable_eks_protection" {
  description = "Enable GuardDuty EKS protection."
  type        = bool
  default     = true
}

variable "enable_rds_protection" {
  description = "Enable GuardDuty RDS protection."
  type        = bool
  default     = true
}

variable "enable_malware_protection_s3" {
  description = "Enable GuardDuty malware protection for S3."
  type        = bool
  default     = false
}

# Security Hub Configuration
variable "aggregator_linking_mode" {
  description = "The linking mode for the Security Hub finding aggregator."
  type        = string
  default     = "SPECIFIED_REGIONS"
}

variable "aggregator_specified_regions" {
  description = "List of regions to include in the Security Hub finding aggregator. The Security Hub home region is always included. This list should represent additional regions you want to include."
  type        = list(string)
  default     = ["us-gov-east-1"]
}