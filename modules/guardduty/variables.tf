variable "audit_account_id" {
  type        = string
  description = "AWS account ID that will serve as the GuardDuty organization administrator (delegated admin)"
}

variable "cross_account_role_name" {
  type        = string
  description = "Name of the role to assume in the audit account for GuardDuty management"
  default     = "OrganizationAccountAccessRole"
}

variable "global_tags" {
  type        = map(string)
  description = "Global tags to apply to all GuardDuty resources"
  default     = {}
}
