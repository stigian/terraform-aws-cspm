output "awsconfig_status" {
  description = "Status of AWS Config organization setup."
  value = {
    admin_account_id      = var.audit_account_id
    aggregator_name       = aws_config_configuration_aggregator.org.name
    aggregator_arn        = aws_config_configuration_aggregator.org.arn
    conformance_pack_name = var.enable_conformance_pack ? var.conformance_pack_name : null
  }
}
