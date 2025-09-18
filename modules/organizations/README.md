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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_organizations_account.commercial](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_account.govcloud](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_organizational_unit.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_ram_sharing_with_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_sharing_with_organization) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_all_accounts_all_parameters"></a> [all\_accounts\_all\_parameters](#input\_all\_accounts\_all\_parameters) | Complete map of ALL AWS accounts in the organization (managed by either Organizations or Control Tower).<br/><br/>Used for comprehensive outputs (like account\_id\_map) that need to show all accounts. | <pre>map(object({<br/>    name            = string<br/>    email           = string<br/>    ou              = string<br/>    lifecycle       = string<br/>    account_type    = optional(string, "")<br/>    create_govcloud = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_aws_organization_id"></a> [aws\_organization\_id](#input\_aws\_organization\_id) | ID for existing AWS Govcloud Organization. If not provided, the module will create a new organization. | `string` | `null` | no |
| <a name="input_control_tower_enabled"></a> [control\_tower\_enabled](#input\_control\_tower\_enabled) | Whether Control Tower will be deployed with this organization.<br/><br/>**IMPORTANT: This significantly changes OU management behavior:**<br/><br/>When true (Control Tower mode):<br/>- Organizations module will NOT create "Security" and "Sandbox" OUs<br/>- Control Tower landing zone will create and manage these OUs instead<br/>- Accounts targeting Control Tower-managed OUs are temporarily placed at Root<br/>- Control Tower will move them to proper OUs during landing zone deployment<br/>- Enforces Control Tower account requirements (management, log\_archive, audit accounts)<br/>- Validates AccountType tags and specific OU placements<br/><br/>When false (Organizations-only mode):<br/>- Organizations module creates ALL OUs defined in organizational\_units<br/>- No Control Tower integration or constraints<br/>- AccountType tags are optional<br/>- More flexible OU assignments allowed<br/><br/>**Control Tower-managed OUs:** Security, Sandbox<br/>**Organizations-managed OUs:** Infrastructure\_Prod, Infrastructure\_NonProd, Workloads\_Prod, Workloads\_NonProd, Policy\_Staging, Suspended | `bool` | `true` | no |
| <a name="input_enable_runtime_validation"></a> [enable\_runtime\_validation](#input\_enable\_runtime\_validation) | Enable runtime validation checks that query AWS APIs. Set to false for synthetic testing to avoid requiring real AWS resources. | `bool` | `true` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Tags applied to all resources created by this module. | `map(string)` | <pre>{<br/>  "ManagedBy": "opentofu"<br/>}</pre> | no |
| <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units) | Map of Organizational Unit (OU) names to their attributes.<br/><br/>Uses AWS Security Reference Architecture (SRA) standard OUs by default:<br/>- Security: For audit, log archive, and security tooling accounts<br/>- Infrastructure\_Prod/NonProd: For network and shared services accounts<br/>- Workloads\_Prod/NonProd: For application workload accounts<br/>- Sandbox: For experimentation and development<br/>- Policy\_Staging: For testing organizational policies<br/>- Suspended: For decommissioned accounts<br/><br/>**CONTROL TOWER INTEGRATION:**<br/>When control\_tower\_enabled = true:<br/>- "Security" and "Sandbox" OUs are NOT created by this module<br/>- Control Tower landing zone creates and manages these OUs<br/>- Only the remaining OUs are created by the organizations module<br/>- Accounts targeting Control Tower OUs are placed at Root initially, then moved by Control Tower<br/><br/>When control\_tower\_enabled = false:<br/>- ALL OUs defined here are created by the organizations module<br/>- Standard organizational structure with no Control Tower constraints<br/><br/>Example:<br/>  {<br/>    Security = {<br/>      lifecycle = "prod"<br/>      tags      = { Owner = "SecurityTeam" }<br/>    }<br/>  } | <pre>map(object({<br/>    lifecycle = optional(string, "prod") # Default to prod<br/>    tags      = optional(map(string), {})<br/>  }))</pre> | <pre>{<br/>  "Infrastructure_NonProd": {<br/>    "lifecycle": "nonprod"<br/>  },<br/>  "Infrastructure_Prod": {<br/>    "lifecycle": "prod"<br/>  },<br/>  "Policy_Staging": {<br/>    "lifecycle": "nonprod"<br/>  },<br/>  "Sandbox": {<br/>    "lifecycle": "nonprod"<br/>  },<br/>  "Security": {<br/>    "lifecycle": "prod"<br/>  },<br/>  "Suspended": {<br/>    "lifecycle": "nonprod"<br/>  },<br/>  "Workloads_NonProd": {<br/>    "lifecycle": "nonprod"<br/>  },<br/>  "Workloads_Prod": {<br/>    "lifecycle": "prod"<br/>  }<br/>}</pre> | no |
| <a name="input_organizations_account_parameters"></a> [organizations\_account\_parameters](#input\_organizations\_account\_parameters) | Accounts managed by the Organizations module (resource creation/moves).<br/><br/>PREREQUISITE: All accounts must already exist (created via AWS Organizations CLI).<br/><br/>Structure:<br/>  {<br/>    "123456789012" = {<br/>      name         = "YourCorp-Management"<br/>      email        = "aws-mgmt@yourcorp.com"<br/>      ou           = "Root"<br/>      lifecycle    = "prod"<br/>      account\_type = "management"<br/>    }<br/>  }<br/><br/>With Control Tower enabled, exclude CT-managed core accounts (management, log\_archive, audit) if CT manages them. | <pre>map(object({<br/>    name            = string<br/>    email           = string<br/>    ou              = string<br/>    lifecycle       = string<br/>    account_type    = optional(string, "")<br/>    create_govcloud = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of the project or application. Used for resource naming and tagging. | `string` | `"CnScca"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id_map"></a> [account\_id\_map](#output\_account\_id\_map) | Map of account names to account IDs for use by other modules (e.g., SSO, Control Tower). |
| <a name="output_account_organizational_units"></a> [account\_organizational\_units](#output\_account\_organizational\_units) | Map of account IDs to their OU names. |
| <a name="output_account_resources"></a> [account\_resources](#output\_account\_resources) | Map of account resources (abstracts commercial vs govcloud partition differences) |
| <a name="output_account_role_mapping"></a> [account\_role\_mapping](#output\_account\_role\_mapping) | Map of account names to their AccountType tags for use by SSO module |
| <a name="output_audit_account_id"></a> [audit\_account\_id](#output\_audit\_account\_id) | Account ID for the audit account (required for Control Tower) |
| <a name="output_aws_partition"></a> [aws\_partition](#output\_aws\_partition) | The AWS partition (aws or aws-us-gov) where the organization is running. |
| <a name="output_global_tags"></a> [global\_tags](#output\_global\_tags) | Global tags for use by submodules. |
| <a name="output_is_govcloud"></a> [is\_govcloud](#output\_is\_govcloud) | Boolean indicating if the organization is running in AWS GovCloud. |
| <a name="output_log_archive_account_id"></a> [log\_archive\_account\_id](#output\_log\_archive\_account\_id) | Account ID for the log archive account (required for Control Tower) |
| <a name="output_management_account_id"></a> [management\_account\_id](#output\_management\_account\_id) | Account ID for the management account (required for Control Tower) |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | The AWS Organization ID. |
| <a name="output_organizational_unit_ids"></a> [organizational\_unit\_ids](#output\_organizational\_unit\_ids) | Map of OU names to their AWS Organization Unit IDs. |
| <a name="output_project"></a> [project](#output\_project) | Project name for use by submodules. |
<!-- END_TF_DOCS -->