variable "identifier" {
  type        = string
  description = "Name of the project or application."
  default     = "demo"
}

variable "aws_region" {
  type        = string
  description = "Home region for Control Tower Landing Zone and tf backend state."
  default     = "us-gov-west-1"
}

variable "account_id_map" {
  type        = map(string)
  description = <<-EOT
    Mapping of account names to govcloud account IDs. Update the example account
    IDs to suit your environment. Account descriptions are:
      - management: AWS Management account, usually the first account created
      - hubandspoke: AWS Hub-and-Spoke account, created manually
      - log: AWS Log Archive account, to be enrolled in AWS Control Tower
      - audit: AWS Audit account, to be enrolled in AWS Control Tower

    Example:
    {
      "management"  = "111111111111"
      "hubandspoke" = "222222222222"
      "log"         = "333333333333"
      "audit"       = "444444444444"
    }
  EOT
}

variable "aws_organization_id" {
  type        = string
  description = "ID for existing AWS Govcloud Organization."
}

variable "central_bucket_name_prefix" {
  type        = string
  description = "Name prefix for S3 bucket in log account where logs are aggregated for all accounts."
  default     = "org-central-logs"
}

variable "key_admin_arns" {
  type        = list(string)
  description = "List of ARNs for additional key administrators who can manage keys in the log archive account."
  default     = []
}
