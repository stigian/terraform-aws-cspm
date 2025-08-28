data "aws_partition" "current" {}

resource "aws_organizations_delegated_administrator" "config" {
  provider          = aws.management
  account_id        = var.audit_account_id
  service_principal = "config.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "config_multiaccountsetup" {
  provider          = aws.management
  account_id        = var.audit_account_id
  service_principal = "config-multiaccountsetup.amazonaws.com"
}

resource "aws_iam_role" "aggregator" {
  provider = aws.audit
  name     = "AWSConfigAggregatorRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy" "aggregator" {
  name = "AWSConfigRoleForOrganizations"
}

resource "aws_iam_role_policy_attachment" "aggregator_policy" {
  provider   = aws.audit
  role       = aws_iam_role.aggregator.name
  policy_arn = data.aws_iam_policy.aggregator.arn
}

resource "aws_config_configuration_aggregator" "org" {
  provider = aws.audit
  name     = var.aggregator_name

  organization_aggregation_source {
    role_arn    = aws_iam_role.aggregator.arn
    all_regions = var.aggregator_all_regions
  }

  depends_on = [
    aws_organizations_delegated_administrator.config,
    aws_organizations_delegated_administrator.config_multiaccountsetup,
  ]
}

/*
** TODO: finish stub below to enable Config recording in the management account
**       and delivery to the Control Tower bucket in the logging account. The
**       Landing Zone configuration of Control Tower makes this very annoying.
**       Getting the right KMS and bucket permissions is critical to getting
**       the delivery channel created successfully.
** See: https://repost.aws/questions/QUF9Umvk9aTkyL78HJJ-vYRg/enabling-aws-configuration-on-control-tower-main-account

resource "aws_iam_service_linked_role" "config" {
  provider          = aws.management
  aws_service_name  = "config.amazonaws.com"
}

resource "aws_config_configuration_recorder" "mgmt" {
  name     = "cnscca-org-mgmt-recorder"
  role_arn = aws_iam_service_linked_role.config.arn
}

resource "aws_config_configuration_recorder_status" "mgmt" {
  name       = aws_config_configuration_recorder.mgmt.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.mgmt]
}

resource "aws_config_delivery_channel" "mgmt" {
  name           = "cnscca-org-mgmt-delivery-channel"
  s3_bucket_name = var.ct_logs_bucket_name
  depends_on     = [aws_config_configuration_recorder.mgmt]
}
*/