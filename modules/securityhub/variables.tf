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
  description = "The linking mode for the Security Hub finding aggregator. 'SPECIFIED_REGIONS' (recommended) includes only the regions specified in aggregator_specified_regions. 'ALL_REGIONS' includes all AWS regions which can be excessive for most deployments."
  type        = string
  default     = "SPECIFIED_REGIONS"

  validation {
    condition     = contains(["ALL_REGIONS", "SPECIFIED_REGIONS"], var.aggregator_linking_mode)
    error_message = "The aggregator_linking_mode must be either 'ALL_REGIONS' or 'SPECIFIED_REGIONS'."
  }
}

variable "aggregator_specified_regions" {
  description = "List of regions to include in the Security Hub finding aggregator when using 'SPECIFIED_REGIONS' linking mode. Ignored when linking_mode is 'ALL_REGIONS'."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}