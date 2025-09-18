variable "member_account_id" {
  description = "The member account ID, excluding the management, audit, and log_archive accounts"
  type        = string
}

variable "management_account_id" {
  description = "The management account ID"
  type        = string
}

variable "global_tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
}
