variable "audit_account_id" {
  description = "The AWS account ID for the audit account."
  type        = string
}

variable "member_account_ids_map" {
  description = <<-EOT
    Mapping of member account names to their AWS account IDs, excluding the audit account.

    Example:
      {
        "WorkloadProd"     = "123456789012",
        "WorkloadNonprod"  = "234567890123"
      }
  EOT
  type        = map(string)
}

variable "global_tags" {
  type        = map(string)
  description = "Global tags to apply to all Detective resources"
  default     = {}
}
