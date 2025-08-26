variable "config_directory" {
  description = "Path to the directory containing YAML configuration files."
  type        = string
  default     = "./config"
}

variable "aws_region" {
  description = "AWS region for the organization. Default is us-gov-west-1."
  type        = string
  default     = "us-gov-west-1"
}

variable "enable_locals_validation" {
  description = "Whether to enable validation checks on local variables."
  type        = bool
  default     = true
}

variable "org_exec_role" {
  description = "The role name in member accounts to assume for Organization access. Must exist ahead of time."
  type        = string
  default     = "OrganizationAccountAccessRole"
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

variable "control_tower_enabled" {
  description = "Whether Control Tower will be deployed with this organization."
  type        = bool
  default     = true
}

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

###############################################################################
# GuardDuty Protection Plan Options
###############################################################################

variable "enable_s3_protection" {
  type        = bool
  description = "Enable S3 Protection to monitor S3 data events for suspicious access patterns. Recommended for DISA SCCA compliance."
  default     = true
}

variable "enable_runtime_monitoring" {
  type        = bool
  description = "Enable Runtime Monitoring for EC2, EKS, and ECS workloads using eBPF-based agents. Critical for DoD environments."
  default     = true
}

variable "enable_malware_protection_ec2" {
  type        = bool
  description = "Enable Malware Protection for EC2 to scan EBS volumes when suspicious activity is detected. Most enterprise customers use dedicated EDR solutions (Microsoft Defender, CrowdStrike, etc.) which provide superior real-time protection."
  default     = false
}

variable "enable_lambda_protection" {
  type        = bool
  description = "Enable Lambda Protection to monitor VPC Flow Logs for Lambda network activity. Enable if using Lambda functions extensively."
  default     = false
}

variable "enable_eks_protection" {
  type        = bool
  description = "Enable EKS Protection to monitor Kubernetes audit logs. Enable only if deploying EKS clusters."
  default     = false
}

variable "enable_rds_protection" {
  type        = bool
  description = "Enable RDS Protection to monitor Aurora database login activity for anomalies. Enable if using RDS Aurora."
  default     = false
}

variable "enable_malware_protection_s3" {
  type        = bool
  description = "Enable S3 Malware Protection for specific untrusted buckets. Not intended for organization-wide deployment."
  default     = false
}

variable "malware_protection_s3_buckets" {
  type        = list(string)
  description = "List of S3 bucket names to enable malware protection. Only used if enable_malware_protection_s3 is true."
  default     = []

  validation {
    condition     = var.enable_malware_protection_s3 == false || length(var.malware_protection_s3_buckets) > 0
    error_message = "If enable_malware_protection_s3 is true, at least one S3 bucket must be specified in malware_protection_s3_buckets."
  }
}

##############
# AWS Config #
##############

variable "enable_conformance_pack" {
  type        = bool
  description = "Enable NIST 800-53r5 Conformance Pack in all member accounts."
  default     = false
}

variable "config_delivery_bucket" {
  description = "S3 bucket name used by AWS Config delivery channels."
  type        = string
  default     = ""
}

variable "manage_recorders" {
  description = "Whether to create per-account AWS Config recorders. Not necessary if member accounts are enrolled in AWS Control Tower."
  type        = bool
  default     = false
}



##########
# Legacy #
##########

# variable "central_bucket_name_prefix" {
#   type        = string
#   description = "Name prefix for S3 bucket in log account where logs are aggregated for all accounts."
#   default     = "org-central-logs"
# }