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
