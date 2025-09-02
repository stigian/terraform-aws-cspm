# https://aws.github.io/aws-security-services-best-practices/guides/security-hub/

data "aws_partition" "audit" { provider = aws.audit }
data "aws_region" "audit" { provider = aws.audit }
data "aws_organizations_organization" "management" {}

resource "aws_securityhub_organization_admin_account" "this" {
  # provider         = aws.management
  admin_account_id = var.audit_account_id
}

resource "aws_securityhub_organization_configuration" "this" {
  provider              = aws.audit
  auto_enable           = false
  auto_enable_standards = "NONE"
  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [
    aws_securityhub_organization_admin_account.this,
    aws_securityhub_finding_aggregator.this,
  ]
}

resource "aws_securityhub_configuration_policy" "this" {
  provider    = aws.audit
  name        = "cnscca-baseline"
  description = "Baseline configuration policy"

  configuration_policy {
    service_enabled = true
    enabled_standard_arns = [
      "arn:${data.aws_partition.audit.partition}:securityhub:${data.aws_region.audit.region}::standards/aws-foundational-security-best-practices/v/1.0.0",
      "arn:${data.aws_partition.audit.partition}:securityhub:${data.aws_region.audit.region}::standards/nist-800-53/v/5.0.0",
    ]
    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }

  depends_on = [aws_securityhub_organization_configuration.this]
}

# Associate the policy with the root OU. Apply will complete before the policy
# fully propagates to all accounts. You can track rollout progress in the audit
# account -> Security Hub -> Settings -> Configuration -> Organization tab.
resource "aws_securityhub_configuration_policy_association" "root" {
  provider  = aws.audit
  target_id = data.aws_organizations_organization.management.roots[0].id
  policy_id = aws_securityhub_configuration_policy.this.id
}

resource "aws_securityhub_insight" "critical" {
  provider = aws.audit
  name     = "_CriticalFindings"
  filters {
    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }
  group_by_attribute = "AwsAccountId"

  depends_on   = [
    aws_securityhub_organization_admin_account.this # optional, added to avoid timing issue
  ]
}

# Using symbols in the name to ensure these are always at the top of the list
resource "aws_securityhub_insight" "high" {
  provider = aws.audit
  name     = "_HighFindings"
  filters {
    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
  }
  group_by_attribute = "AwsAccountId"

  depends_on   = [
    aws_securityhub_organization_admin_account.this # optional, added to avoid timing issue
  ]
}

resource "aws_securityhub_finding_aggregator" "this" {
  provider     = aws.audit
  linking_mode = "ALL_REGIONS"
  depends_on   = [aws_securityhub_organization_admin_account.this]
}
