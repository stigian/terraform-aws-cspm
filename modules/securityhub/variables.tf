variable "management_account_id" {
  description = "The AWS account ID of the management account"
  type        = string
}

variable "audit_account_id" {
  description = "The AWS account ID of the audit account"
  type        = string
}

variable "global_tags" {
  description = "A map of tags to apply globally"
  type        = map(string)
}

variable "aggregator_linking_mode" {
  description = "The linking mode for the Config aggregator. Determines which regions are included."
  type        = string
  default     = "SPECIFIED_REGIONS"
}

variable "aggregator_specified_regions" {
  description = "List of regions to include in the Config aggregator when using SPECIFIED_REGIONS linking mode."
  type        = list(string)
  default     = ["us-gov-west-1", "us-gov-east-1"]
}