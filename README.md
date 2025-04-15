# terraform-aws-cspm

This module configures Cloud Security Posture Management (CSPM) in support of the DoD Zero Trust strategy. The design relies on the AWS Control Tower Landing Zone baseline version 3.3 as a starting point. Additional services are delegated, activated, and configured across the entire AWS Organization including:

- GuardDuty
- Detective
- Inspector
- Security Hub
- Config
- CloudTrail
- IAM Identity Center

[AWS Security Services Best Practices](https://aws.github.io/aws-security-services-best-practices/) serves as a guide for the default configuration. Configurations for non-security services like AWS Config are also included to ensure compliance with the DoD Zero Trust strategy.

# Service Descriptions

## GuardDuty

Amazon GuardDuty is a threat detection service that continuously monitors for malicious activity and unauthorized behavior to protect your AWS accounts and workloads. GuardDuty is enabled in all accounts in the AWS Organization. The audit account is the master account for GuardDuty. Member accounts are enabled and configured to send findings to the master account.

## Detective

Amazon Detective makes it easy to analyze, investigate, and quickly identify the root cause of security findings or suspicious activities. Detective automatically collects log data from your AWS resources and uses machine learning, statistical analysis, and graph theory to help you visualize and conduct faster and more efficient security investigations.


## Inspector

Amazon Inspector is a vulnerability management service that continuously monitors your AWS workloads for software vulnerabilities and unintended network exposure. Amazon Inspector automatically discovers and scans running Amazon EC2 instances, container images in Amazon Elastic Container Registry (Amazon ECR), and AWS Lambda functions.


## Security Hub

AWS Security Hub provides you with a comprehensive view of your security state within AWS and helps you check your environment against security industry standards and best practices. Security Hub is enabled in all accounts in the AWS Organization. The audit account is the master account for Security Hub. Member accounts are enabled and configured to send findings to the master account.

## Config

AWS Config provides a detailed view of the resources associated with your AWS account, including how they are configured, how they are related to one another, and how the configurations and their relationships have changed over time. AWS Config resources provisioned by AWS Control Tower are tagged automatically with `aws-control-tower` and a value of `managed-by-control-tower`.

## CloudTrail

AWS Control Tower configures AWS CloudTrail to enable centralized logging and auditing for all accounts. With CloudTrail, the management account can review administrative actions and lifecycle events for member accounts.


## IAM Identity Center

AWS Control Tower configures IAM Identity Center to provide a centralized view of identity and access management (IAM) activity across all accounts in the AWS Organization. IAM Identity Center provides a single location to view and manage IAM activity, including changes to IAM policies, roles, and users.


# Pre-deployment steps

In Govcloud, create and add accounts to the AWS Organization. The accounts do not need to be placed into Organizational Units (OUs) ahead of time. Control Tower will place the log archive and audit accounts into the proper OUs. We recommend moving the hub-and-spoke account to the _Sandbox_ OU after the module has finished provisioning. You may wish to create additional OUs like _Production_ or _Development_ to suit your specific needs. These OUs will inherit the baseline guardrails applied at the root of the Organization. The minimum accounts you need to create are:

- Management
- Hub-and-spoke
- Log archive
- Audit


# Post-deployment steps


## GuardDuty

> [!NOTE]
> Enabling member accounts is not retroactive, so you must enable them manually.

1. Login to the audit account
1. Navigate to _Accounts_ in the left hand pane
1. Verify every account _Status_ column shows _Enabled_
1. If not, select the checkbox next to each account, click _Actions_, click _Add member_


## Detective

> [!NOTE]
> Enabling member accounts is not retroactive, so you must enable them manually.

1. Login to the audit account
1. Navigate to _Settings_ -> _Account management_ in the left hand pane
1. Verify member accounts _Status_ column shows _Enabled_
1. If not, simply click the _Enable all accounts_ button


## Inspector

No action required.


## Control Tower

No action required.

If in the future you need to enroll/onboard new accounts to Control Tower, see these references:

- [Enroll an existing AWS account | AWS Docs](https://docs.aws.amazon.com/controltower/latest/userguide/enroll-account.html)
- [Field Notes: Enroll Existing AWS Accounts into AWS Control Tower | AWS Blogs](https://aws.amazon.com/blogs/architecture/field-notes-enroll-existing-aws-accounts-into-aws-control-tower/) for more information.


## Security Hub

No action required.

Insight categories for Critical and High findings are automatically configured. Depending on your specific security posture you may wish to [fine tune the Security Standard controls](https://aws.github.io/aws-security-services-best-practices/guides/security-hub/#fine-tuning-security-standard-controls) to reduce noise.


## Config

No action required.


## CloudTrail

No action required.


## IAM Identity Center

No action required.

Control Tower applies a basic configuration for IAM Identity Center in the management account. We choose _not_ to delegate administration of IAM Identity Center to another account, instead leaving it in the management account. This is because the management account is the root account and has the highest level of permissions. We recommend that you do not delegate IAM Identity Center to another account unless you have a specific use case that requires it.

Customizations to IAM Identity Center such as transitioning to an external identity provider may be applied separately. See the [AWS docs](https://docs.aws.amazon.com/singlesignon/latest/userguide/manage-your-identity-source-considerations.html#changing-from-idc-and-idp) for more information.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.audit"></a> [aws.audit](#provider\_aws.audit) | >= 5.0.0 |
| <a name="provider_aws.hubandspoke"></a> [aws.hubandspoke](#provider\_aws.hubandspoke) | >= 5.0.0 |
| <a name="provider_aws.log"></a> [aws.log](#provider\_aws.log) | >= 5.0.0 |
| <a name="provider_aws.management"></a> [aws.management](#provider\_aws.management) | >= 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_central_bucket"></a> [central\_bucket](#module\_central\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 4.3 |
| <a name="module_s3_anfw_logs"></a> [s3\_anfw\_logs](#module\_s3\_anfw\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 4.3 |
| <a name="module_s3_lb_logs"></a> [s3\_lb\_logs](#module\_s3\_lb\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 4.3 |
| <a name="module_s3_org_cloudtrail_logs"></a> [s3\_org\_cloudtrail\_logs](#module\_s3\_org\_cloudtrail\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 4.3 |
| <a name="module_s3_org_config_logs"></a> [s3\_org\_config\_logs](#module\_s3\_org\_config\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 4.3 |
| <a name="module_s3_server_access_logs"></a> [s3\_server\_access\_logs](#module\_s3\_server\_access\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 4.3 |
| <a name="module_s3_vpc_flow_logs"></a> [s3\_vpc\_flow\_logs](#module\_s3\_vpc\_flow\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 4.3 |
| <a name="module_s3_waf_logs"></a> [s3\_waf\_logs](#module\_s3\_waf\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 4.3 |

## Resources

| Name | Type |
|------|------|
| [aws_config_organization_conformance_pack.nist_800_53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_conformance_pack) | resource |
| [aws_controltower_landing_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/controltower_landing_zone) | resource |
| [aws_detective_graph.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/detective_graph) | resource |
| [aws_detective_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/detective_organization_admin_account) | resource |
| [aws_detective_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/detective_organization_configuration) | resource |
| [aws_guardduty_detector.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_detector.hubandspoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_detector.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_detector.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_guardduty_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_iam_policy.combined_logs_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.hubandspoke_to_central](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.combined_logs_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.hubandspoke_to_central](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.combined_logs_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.hubandspoke_to_central](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_service_linked_role.audit_agentless_inspector2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_iam_service_linked_role.audit_detective](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_iam_service_linked_role.hubandspoke_agentless_inspector2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_iam_service_linked_role.hubandspoke_detective](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_iam_service_linked_role.hubandspoke_inspector2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_iam_service_linked_role.log_agentless_inspector2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_iam_service_linked_role.log_detective](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_iam_service_linked_role.log_inspector2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_inspector2_delegated_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_delegated_admin_account) | resource |
| [aws_inspector2_enabler.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_enabler) | resource |
| [aws_inspector2_member_association.hubandspoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_member_association) | resource |
| [aws_inspector2_member_association.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_member_association) | resource |
| [aws_inspector2_member_association.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_member_association) | resource |
| [aws_inspector2_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_organization_configuration) | resource |
| [aws_kms_alias.central_log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.control_tower](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.hubandspoke_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.central_log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.control_tower](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.hubandspoke_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.central_log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_kms_key_policy.control_tower](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_kms_key_policy.hubandspoke_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_organizations_delegated_administrator.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_delegated_administrator.config_multiaccountsetup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_s3_bucket_replication_configuration.combined_logs_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_securityhub_configuration_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy) | resource |
| [aws_securityhub_configuration_policy_association.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy_association) | resource |
| [aws_securityhub_insight.critical](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_insight) | resource |
| [aws_securityhub_insight.high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_insight) | resource |
| [aws_securityhub_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |
| [aws_caller_identity.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.hubandspoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.anfw_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.central_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_log_delivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.combined_logs_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.config_log_delivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.hubandspoke_to_central](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.waf_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_roles.log_sso_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_organizations_organization.hubandspoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_organization.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_organizational_units.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |
| [aws_partition.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_partition.hubandspoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_partition.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_partition.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_region.hubandspoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_region.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.ct_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id_map"></a> [account\_id\_map](#input\_account\_id\_map) | Mapping of account names to govcloud account IDs. Update the example account<br/>IDs to suit your environment. Account descriptions are:<br/>  - management: AWS Management account, usually the first account created<br/>  - hubandspoke: AWS Hub-and-Spoke account, created manually<br/>  - log: AWS Log Archive account, to be enrolled in AWS Control Tower<br/>  - audit: AWS Audit account, to be enrolled in AWS Control Tower<br/><br/>Example:<br/>{<br/>  "management"  = "111111111111"<br/>  "hubandspoke" = "222222222222"<br/>  "log"         = "333333333333"<br/>  "audit"       = "444444444444"<br/>} | `map(string)` | n/a | yes |
| <a name="input_aws_organization_id"></a> [aws\_organization\_id](#input\_aws\_organization\_id) | ID for existing AWS Govcloud Organization. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Home region for Control Tower Landing Zone and tf backend state. | `string` | `"us-gov-west-1"` | no |
| <a name="input_central_bucket_name_prefix"></a> [central\_bucket\_name\_prefix](#input\_central\_bucket\_name\_prefix) | Name prefix for S3 bucket in log account where logs are aggregated for all accounts. | `string` | `"org-central-logs"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Name of the project or application. | `string` | `"demo"` | no |
| <a name="input_key_admin_arns"></a> [key\_admin\_arns](#input\_key\_admin\_arns) | List of ARNs for additional key administrators who can manage keys in the log archive account. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_central_bucket_arn"></a> [central\_bucket\_arn](#output\_central\_bucket\_arn) | n/a |
| <a name="output_central_bucket_kms_key_arn"></a> [central\_bucket\_kms\_key\_arn](#output\_central\_bucket\_kms\_key\_arn) | n/a |
<!-- END_TF_DOCS -->