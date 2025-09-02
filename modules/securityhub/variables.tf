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