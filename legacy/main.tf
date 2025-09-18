
###############################################################################
# Amazon Inspector
#
# https://aws.github.io/aws-security-services-best-practices/guides/inspector/
###############################################################################

# Side-effect: creates 2x service-linked roles in management account
# Side-effect: creates 1x service-linked role in audit account
resource "aws_inspector2_delegated_admin_account" "this" {
  provider   = aws.management         # from
  account_id = local.audit_account_id # to
  depends_on = [aws_organizations_organization.this]
}

resource "aws_inspector2_organization_configuration" "this" {
  provider = aws.audit
  auto_enable {
    ec2         = true
    ecr         = true
    lambda      = true
    lambda_code = false # Not supported in GovCloud
  }

  depends_on = [aws_inspector2_delegated_admin_account.this]
}

resource "aws_inspector2_member_association" "log" {
  provider   = aws.audit
  account_id = var.account_id_map["log"]
  depends_on = [aws_inspector2_organization_configuration.this]
}

resource "aws_inspector2_member_association" "management" {
  provider   = aws.audit
  account_id = var.account_id_map["management"]
  depends_on = [aws_inspector2_organization_configuration.this]
}

resource "aws_inspector2_member_association" "hubandspoke" {
  provider   = aws.audit
  account_id = var.account_id_map["hubandspoke"]
  depends_on = [aws_inspector2_organization_configuration.this]
}

resource "aws_inspector2_enabler" "audit" {
  provider       = aws.audit
  account_ids    = [local.audit_account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
  depends_on     = [aws_inspector2_organization_configuration.this]
}
