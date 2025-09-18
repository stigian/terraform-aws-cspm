###############################################################################
# Amazon Detective - Organization-wide Security Investigation
#
# This module enables Detective for comprehensive security investigation capabilities
# across the organization. Detective automatically ingests and analyzes data from
# GuardDuty, Security Hub, and AWS security logs to provide investigation graphs.
#
# Architecture:
# - Behavior graph created in audit account (delegated administrator)
# - All organization accounts automatically invited and enrolled
# - 30-day data retention for investigation capabilities
#
# Dependencies:
# - GuardDuty must be enabled organization-wide (data source requirement)
# - Audit account designated as delegated administrator
#
# https://docs.aws.amazon.com/detective/latest/adminguide/detective-organization-management.html
###############################################################################

# Step 1: Designate audit account as Detective organization administrator
# This is done from the management account (default provider)
resource "aws_detective_organization_admin_account" "this" {
  account_id = var.audit_account_id
}

# Step 2: Create Detective behavior graph in audit account
# The behavior graph collects and processes security data for investigation
resource "aws_detective_graph" "organization" {
  provider = aws.audit

  tags = var.global_tags

  depends_on = [aws_detective_organization_admin_account.this]
}

# Step 3: Configure organization-wide Detective auto-enrollment
# This automatically invites and enables Detective for all organization members
resource "aws_detective_organization_configuration" "auto_enable" {
  provider  = aws.audit
  graph_arn = aws_detective_graph.organization.graph_arn

  # Automatically enable Detective for all organization accounts
  auto_enable = true

  depends_on = [aws_detective_graph.organization]
}
