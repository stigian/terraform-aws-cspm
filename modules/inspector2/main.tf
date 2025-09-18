
###############################################################################
# Amazon Inspector
#
# https://aws.github.io/aws-security-services-best-practices/guides/inspector/
###############################################################################

# Side-effect: creates 2x service-linked roles in management account
# Side-effect: creates 1x service-linked role in audit account
resource "aws_inspector2_delegated_admin_account" "this" {
  provider   = aws.management         # from
  account_id = var.audit_account_id    # to
}

resource "aws_inspector2_enabler" "audit" {
  provider       = aws.audit
  account_ids    = [var.audit_account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
}

resource "aws_inspector2_organization_configuration" "this" {
  provider = aws.audit
  auto_enable {
    ec2         = true
    ecr         = true
    lambda      = true
    lambda_code = false # Not supported in GovCloud
  }

  depends_on = [
    aws_inspector2_delegated_admin_account.this,
    aws_inspector2_enabler.audit
  ]
}

resource "aws_inspector2_member_association" "this" {
  for_each   = var.member_account_ids_map
  provider   = aws.audit
  account_id = each.value
  depends_on = [aws_inspector2_organization_configuration.this]
}
