variable "audit_account_id" { type = string }
variable "organization_id" { type = string }
variable "global_tags" { type = map(string) }
variable "aggregator_name" {
  type        = string
  default     = "cnscca-org-config-aggregator"
  description = "The name of the AWS Config aggregator."
}

variable "aggregator_all_regions" {
  type        = bool
  default     = true
  description = "Whether to aggregate AWS Config data from all regions."
}

variable "enable_kms" {
  type        = bool
  default     = true
  description = "Whether to enable KMS encryption for the S3 bucket."
}

variable "kms_key_alias" {
  type        = string
  default     = "cnscca-org-config-key"
  description = "The alias for the KMS key used for S3 bucket encryption."
}
