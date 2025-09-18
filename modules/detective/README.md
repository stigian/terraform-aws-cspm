<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
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
| [aws_detective_graph.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/detective_graph) | resource |
| [aws_detective_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/detective_organization_admin_account) | resource |
| [aws_detective_organization_configuration.auto_enable](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/detective_organization_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | AWS account ID that will serve as the Detective organization administrator (delegated admin) | `string` | n/a | yes |
| <a name="input_cross_account_role_name"></a> [cross\_account\_role\_name](#input\_cross\_account\_role\_name) | Name of the role to assume in the audit account for Detective management | `string` | `"OrganizationAccountAccessRole"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags to apply to all Detective resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_detective_status"></a> [detective\_status](#output\_detective\_status) | Complete Detective deployment status including behavior graph details and organization configuration |
<!-- END_TF_DOCS -->