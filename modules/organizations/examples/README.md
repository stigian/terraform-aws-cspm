## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_organizations"></a> [organizations](#module\_organizations) | ../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_parameters"></a> [aws\_account\_parameters](#input\_aws\_account\_parameters) | Map of AWS account parameters following AWS SRA account taxonomy.<br/><br/>**IMPORTANT**: <br/>- All accounts must already exist - this module does not create accounts<br/>- Account IDs must be exactly 12 digits<br/>- Account names must be unique<br/>- Email addresses must match actual account email addresses<br/>- Management account should use ou = "Root"<br/><br/>Example account types following AWS SRA:<br/>- Management: Organization management account<br/>- Log Archive: Centralized logging account<br/>- Audit: Security audit and compliance account<br/>- Network: Central network connectivity account<br/>- Shared Services: Shared infrastructure services<br/>- Security Tooling: Security tools and SIEM<br/>- Backup: Centralized backup and recovery<br/>- Workload accounts: Application workloads (prod/nonprod/sandbox) | <pre>map(object({<br/>    email           = string<br/>    lifecycle       = string<br/>    name            = string<br/>    ou              = string<br/>    tags            = optional(map(string), {})<br/>    create_govcloud = optional(bool, false)<br/>  }))</pre> | <pre>{<br/>  "111111111111": {<br/>    "create_govcloud": false,<br/>    "email": "aws-management@organization.com",<br/>    "lifecycle": "prod",<br/>    "name": "Management Account",<br/>    "ou": "Root",<br/>    "tags": {<br/>      "AccountType": "management"<br/>    }<br/>  },<br/>  "222222222222": {<br/>    "create_govcloud": true,<br/>    "email": "aws-log-archive@organization.com",<br/>    "lifecycle": "prod",<br/>    "name": "Security Log Archive",<br/>    "ou": "Security",<br/>    "tags": {<br/>      "AccountType": "log_archive"<br/>    }<br/>  },<br/>  "333333333333": {<br/>    "create_govcloud": true,<br/>    "email": "aws-audit@organization.com",<br/>    "lifecycle": "prod",<br/>    "name": "Security Audit",<br/>    "ou": "Security",<br/>    "tags": {<br/>      "AccountType": "audit"<br/>    }<br/>  },<br/>  "444444444444": {<br/>    "create_govcloud": true,<br/>    "email": "aws-network@organization.com",<br/>    "lifecycle": "prod",<br/>    "name": "Infrastructure Network",<br/>    "ou": "Infrastructure_Prod",<br/>    "tags": {<br/>      "AccountType": "network"<br/>    }<br/>  },<br/>  "555555555555": {<br/>    "create_govcloud": true,<br/>    "email": "aws-shared-services@organization.com",<br/>    "lifecycle": "prod",<br/>    "name": "Infrastructure Shared",<br/>    "ou": "Infrastructure_Prod",<br/>    "tags": {<br/>      "AccountType": "shared_services"<br/>    }<br/>  },<br/>  "666666666666": {<br/>    "create_govcloud": true,<br/>    "email": "aws-security-tools@organization.com",<br/>    "lifecycle": "prod",<br/>    "name": "Security Tooling",<br/>    "ou": "Security",<br/>    "tags": {<br/>      "AccountType": "security_tooling"<br/>    }<br/>  },<br/>  "777777777777": {<br/>    "create_govcloud": true,<br/>    "email": "aws-workload-prod@organization.com",<br/>    "lifecycle": "prod",<br/>    "name": "Workload Production",<br/>    "ou": "Workloads_Prod",<br/>    "tags": {<br/>      "AccountType": "workload_prod"<br/>    }<br/>  },<br/>  "888888888888": {<br/>    "create_govcloud": false,<br/>    "email": "aws-workload-dev@organization.com",<br/>    "lifecycle": "nonprod",<br/>    "name": "Workload Development",<br/>    "ou": "Workloads_Test",<br/>    "tags": {<br/>      "AccountType": "workload_nonprod"<br/>    }<br/>  },<br/>  "999999999999": {<br/>    "create_govcloud": false,<br/>    "email": "aws-sandbox@organization.com",<br/>    "lifecycle": "nonprod",<br/>    "name": "Workload Sandbox",<br/>    "ou": "Sandbox",<br/>    "tags": {<br/>      "AccountType": "workload_sandbox"<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources in | `string` | `"us-gov-west-1"` | no |
| <a name="input_enable_entra_integration"></a> [enable\_entra\_integration](#input\_enable\_entra\_integration) | Whether to enable Entra ID integration in SSO module | `bool` | `false` | no |
| <a name="input_enable_sso_management"></a> [enable\_sso\_management](#input\_enable\_sso\_management) | Whether to enable SSO module integration for Identity Center management | `bool` | `false` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | A map of tags to add to all resources. These are merged with any resource-specific tags. | `map(string)` | <pre>{<br/>  "Owner": "platform-team",<br/>  "Project": "my-project",<br/>  "Repository": "https://github.com/organization/terraform-aws-cspm",<br/>  "Terraform": "true"<br/>}</pre> | no |
| <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units) | Map of Organizational Unit (OU) names to their attributes following AWS SRA structure.<br/><br/>Each OU represents a logical grouping of accounts based on their function and security requirements. | <pre>map(object({<br/>    lifecycle = string<br/>    tags      = optional(map(string), {})<br/>  }))</pre> | <pre>{<br/>  "Infrastructure_Prod": {<br/>    "lifecycle": "prod",<br/>    "tags": {<br/>      "Function": "Infrastructure",<br/>      "Purpose": "Production infrastructure services"<br/>    }<br/>  },<br/>  "Infrastructure_Test": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {<br/>      "Function": "Infrastructure",<br/>      "Purpose": "Development and testing infrastructure"<br/>    }<br/>  },<br/>  "Policy_Staging": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {<br/>      "Function": "Policy",<br/>      "Purpose": "Organization policy testing"<br/>    }<br/>  },<br/>  "Sandbox": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {<br/>      "Function": "Sandbox",<br/>      "Purpose": "Experimental and POC accounts"<br/>    }<br/>  },<br/>  "Security": {<br/>    "lifecycle": "prod",<br/>    "tags": {<br/>      "Function": "Security",<br/>      "Purpose": "Security and compliance accounts"<br/>    }<br/>  },<br/>  "Suspended": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {<br/>      "Function": "Suspended",<br/>      "Purpose": "Suspended or decommissioned accounts"<br/>    }<br/>  },<br/>  "Workloads_Prod": {<br/>    "lifecycle": "prod",<br/>    "tags": {<br/>      "Function": "Workloads",<br/>      "Purpose": "Production application workloads"<br/>    }<br/>  },<br/>  "Workloads_Test": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {<br/>      "Function": "Workloads",<br/>      "Purpose": "Development and testing workloads"<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | Name of the project or application. Used for naming resources. | `string` | `"my-project"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id_map"></a> [account\_id\_map](#output\_account\_id\_map) | Map of account names to their IDs |
| <a name="output_account_mapping"></a> [account\_mapping](#output\_account\_mapping) | Account name to ID mapping for use with other modules |
| <a name="output_account_organizational_units"></a> [account\_organizational\_units](#output\_account\_organizational\_units) | Map of account IDs to their OU names |
| <a name="output_account_structure"></a> [account\_structure](#output\_account\_structure) | Organized view of accounts by OU for verification |
| <a name="output_applied_global_tags"></a> [applied\_global\_tags](#output\_applied\_global\_tags) | Global tags that are applied to all resources |
| <a name="output_aws_partition"></a> [aws\_partition](#output\_aws\_partition) | The AWS partition where the organization is running (aws or aws-us-gov) |
| <a name="output_is_govcloud"></a> [is\_govcloud](#output\_is\_govcloud) | Boolean indicating if running in AWS GovCloud (account name changes will be ignored) |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | The ID of the AWS Organization |
| <a name="output_organization_info"></a> [organization\_info](#output\_organization\_info) | AWS Organization information |
| <a name="output_organizational_unit_ids"></a> [organizational\_unit\_ids](#output\_organizational\_unit\_ids) | Map of OU names to their IDs |
