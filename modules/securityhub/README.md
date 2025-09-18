<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
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
| [aws_securityhub_configuration_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy) | resource |
| [aws_securityhub_configuration_policy_association.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy_association) | resource |
| [aws_securityhub_finding_aggregator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_insight.critical](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_insight) | resource |
| [aws_securityhub_insight.high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_insight) | resource |
| [aws_securityhub_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |
| [aws_securityhub_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |
| [aws_organizations_organization.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_partition.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aggregator_linking_mode"></a> [aggregator\_linking\_mode](#input\_aggregator\_linking\_mode) | The linking mode for the Security Hub finding aggregator. 'SPECIFIED\_REGIONS' (recommended) includes only the regions specified in aggregator\_specified\_regions. 'ALL\_REGIONS' includes all AWS regions which can be excessive for most deployments. | `string` | `"SPECIFIED_REGIONS"` | no |
| <a name="input_aggregator_specified_regions"></a> [aggregator\_specified\_regions](#input\_aggregator\_specified\_regions) | List of regions to include in the Security Hub finding aggregator when using 'SPECIFIED\_REGIONS' linking mode. Ignored when linking\_mode is 'ALL\_REGIONS'. | `list(string)` | <pre>[<br/>  "us-east-1",<br/>  "us-west-2"<br/>]</pre> | no |
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | The AWS account ID of the audit account | `string` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | A map of tags to apply globally | `map(string)` | n/a | yes |
| <a name="input_management_account_id"></a> [management\_account\_id](#input\_management\_account\_id) | The AWS account ID of the management account | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->