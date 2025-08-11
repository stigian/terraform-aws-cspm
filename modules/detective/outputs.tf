###############################################################################
# Detective Module Outputs  
###############################################################################

# Comprehensive Detective status for compliance and operational visibility
output "detective_status" {
  description = "Complete Detective deployment status including behavior graph details and organization configuration"
  value = {
    # Core behavior graph information
    admin_account_id    = var.audit_account_id
    behavior_graph_arn  = aws_detective_graph.organization.graph_arn
    auto_enable_enabled = aws_detective_organization_configuration.auto_enable.auto_enable
  }
}
