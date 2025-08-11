# Enable/disable AWS Config auto-enable submodule
variable "enable_autoenable" {
  description = "Enable automatic AWS Config setup in new accounts using Lambda automation (creates S3, KMS, EventBridge, and Lambda in the audit account). Set to true to enable automatic Config deployment for all new AWS accounts."
  type        = bool
  default     = false
}

# Optional: S3 bucket name for delivery channel
variable "autoenable_bucket_name" {
  description = "Optional: S3 bucket name for AWS Config delivery channel. If not set, a unique name will be generated."
  type        = string
  default     = null
}

# Optional: List of ARNs for KMS key decryption (e.g., security team, Splunk)
variable "autoenable_kms_user_arns" {
  description = "List of IAM ARNs (users, roles, groups) allowed to use the KMS key for decryption (e.g., security team, Splunk, automation)."
  type        = list(string)
  default     = []
}

# Optional: Region for autoenable resources
variable "autoenable_region" {
  description = "Region in which to enable AWS Config auto-enable automation. Should match the region of the aggregator and S3 bucket."
  type        = string
  default     = "us-gov-west-1"
}
variable "audit_account_id" {
  type        = string
  description = "AWS Account ID of the Audit account to delegate AWS Config administration to."
}

variable "aggregator_name" {
  type        = string
  description = "Name for the organization-wide AWS Config configuration aggregator."
  default     = "organization-configuration-aggregator"
}

variable "aggregator_all_regions" {
  type        = bool
  description = "Whether the aggregator should aggregate from all regions."
  default     = true
}

variable "enable_conformance_pack" {
  type        = bool
  description = "Enable deployment of the organization conformance pack (Phase 2)."
  default     = false
}

variable "conformance_pack_name" {
  type        = string
  description = "Name of the organization conformance pack."
  default     = "Operational-Best-Practices-for-NIST-800-53-rev-5"
}

variable "conformance_pack_template_path" {
  type        = string
  description = "Path to the conformance pack template YAML file."
  default     = "templates/Operational-Best-Practices-for-NIST-800-53-rev-5.yaml"
}

variable "conformance_pack_excluded_accounts" {
  type        = list(string)
  description = "List of account IDs to exclude from the organization conformance pack."
  default     = []
}
