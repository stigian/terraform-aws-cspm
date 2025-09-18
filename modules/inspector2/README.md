<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.audit"></a> [aws.audit](#provider\_aws.audit) | >= 5.0.0 |
| <a name="provider_aws.management"></a> [aws.management](#provider\_aws.management) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_inspector2_delegated_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_delegated_admin_account) | resource |
| [aws_inspector2_enabler.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_enabler) | resource |
| [aws_inspector2_member_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_member_association) | resource |
| [aws_inspector2_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_organization_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | The AWS account ID for the audit account. | `string` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags to apply to all Detective resources | `map(string)` | `{}` | no |
| <a name="input_member_account_ids_map"></a> [member\_account\_ids\_map](#input\_member\_account\_ids\_map) | Mapping of member account names to their AWS account IDs, excluding the audit account.<br/><br/>Example:<br/>  {<br/>    "WorkloadProd"     = "123456789012",<br/>    "WorkloadNonprod"  = "234567890123"<br/>  } | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->