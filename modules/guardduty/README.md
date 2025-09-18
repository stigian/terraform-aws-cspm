<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |
| <a name="provider_aws.audit"></a> [aws.audit](#provider\_aws.audit) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_guardduty_detector.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_guardduty_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_guardduty_organization_configuration_feature.eks_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.lambda_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.malware_protection_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.rds_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.runtime_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.s3_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | AWS account ID that will serve as the GuardDuty organization administrator (delegated admin) | `string` | n/a | yes |
| <a name="input_cross_account_role_name"></a> [cross\_account\_role\_name](#input\_cross\_account\_role\_name) | Name of the role to assume in the audit account for GuardDuty management | `string` | `"OrganizationAccountAccessRole"` | no |
| <a name="input_enable_eks_protection"></a> [enable\_eks\_protection](#input\_enable\_eks\_protection) | Enable EKS Protection to monitor Kubernetes audit logs (only if using EKS clusters) | `bool` | `false` | no |
| <a name="input_enable_lambda_protection"></a> [enable\_lambda\_protection](#input\_enable\_lambda\_protection) | Enable Lambda Protection to monitor VPC Flow Logs for Lambda network activity | `bool` | `false` | no |
| <a name="input_enable_malware_protection_ec2"></a> [enable\_malware\_protection\_ec2](#input\_enable\_malware\_protection\_ec2) | Enable Malware Protection for EC2 to scan EBS volumes when suspicious activity is detected. Note: Most enterprise customers use dedicated EDR solutions (Defender, CrowdStrike, etc.) | `bool` | `false` | no |
| <a name="input_enable_malware_protection_s3"></a> [enable\_malware\_protection\_s3](#input\_enable\_malware\_protection\_s3) | Enable S3 Malware Protection for specific untrusted buckets (not organization-wide) | `bool` | `false` | no |
| <a name="input_enable_rds_protection"></a> [enable\_rds\_protection](#input\_enable\_rds\_protection) | Enable RDS Protection to monitor Aurora database login activity for anomalies | `bool` | `false` | no |
| <a name="input_enable_runtime_monitoring"></a> [enable\_runtime\_monitoring](#input\_enable\_runtime\_monitoring) | Enable Runtime Monitoring for EC2, EKS, and ECS workloads using eBPF-based agents. See docs/README.md for agent deployment prerequisites. | `bool` | `true` | no |
| <a name="input_enable_s3_protection"></a> [enable\_s3\_protection](#input\_enable\_s3\_protection) | Enable S3 Protection to monitor S3 data events for suspicious access patterns | `bool` | `true` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags to apply to all GuardDuty resources | `map(string)` | `{}` | no |
| <a name="input_malware_protection_s3_buckets"></a> [malware\_protection\_s3\_buckets](#input\_malware\_protection\_s3\_buckets) | List of S3 bucket names to enable malware protection (only used if enable\_malware\_protection\_s3 is true) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_guardduty_status"></a> [guardduty\_status](#output\_guardduty\_status) | Complete GuardDuty deployment status including organization configuration and protection plans |
<!-- END_TF_DOCS -->
