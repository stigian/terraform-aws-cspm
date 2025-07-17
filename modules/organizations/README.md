# AWS Organizations Submodule

This Terraform module manages AWS Organizations and Organizational Units (OUs) according to best practices from the [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/architecture.html).

---

## Features

- Create or import an AWS Organization
- Dynamically create OUs from a map variable
- Assign **existing** AWS accounts to OUs using a flexible map/object structure
- Merge global and resource-specific tags
- Outputs for organization and OU IDs
- **Automatic GovCloud Support**: Detects AWS GovCloud partition and automatically ignores account name changes

> [!NOTE]
> This module only manages existing AWS accounts. It does not create new accounts at this time.
>
> For GovCloud, the `name` and `email` values must match what is currently set in the AWS Console. These values cannot be changed from GovCloud; updates must be made from the commercial (linked) account.
>
> **Automatic GovCloud Detection**: When running in AWS GovCloud (aws-us-gov partition), the module automatically ignores changes to account names to prevent plan failures, since name changes can only be made from the paired commercial account.

---

## Usage

> [!NOTE]
> Note: This module only manages existing AWS accounts. It does not create new accounts at this time.

```hcl
module "organizations" {
  source = "./modules/organizations"

  project             = "my-project"
  aws_organization_id = null # or set to existing org ID to import

  organizational_units = {
    Security = {
      lifecycle = "prod"
      tags      = { Owner = "SecurityTeam" }
    }
    Workloads_Prod = {
      lifecycle = "prod"
      tags      = {}
    }
    Sandbox = {
      lifecycle = "nonprod"
      tags      = {}
    }
  }

  # All account IDs must refer to existing accounts.
  aws_account_parameters = {
    "111111111111" = {
      email     = "account1@example.com"
      lifecycle = "prod"
      name      = "Management"
      ou        = "Security"
      tags      = { Environment = "Production" }
      create_govcloud = false # Reserved for future use
    }
    "222222222222" = {
      email     = "account2@example.com"
      lifecycle = "nonprod"
      name      = "Workload"
      ou        = "Workloads_Prod"
      tags      = {}
      create_govcloud = false # Reserved for future use
    }
  }

  tags = {
    Project   = "my-project"
    Owner     = "alice"
    Lifecycle = "prod"
  }
}
```

---

## Tagging Behavior

- The `tags` variable provides global tags for all resources.
- Resource-specific tags (e.g., per OU or account) are merged with global tags.
- If a tag key exists in both, the resource-specific value takes precedence.

---

## Account Management Notes

- The `create_govcloud` field in `aws_account_parameters` is reserved for future support of commercial + GovCloud account creation and is currently ignored.
- All accounts must already exist; this module does not create new accounts yet.

---

## Outputs Example

```hcl
output "organization_id" {
  value = module.organizations.organization_id
}
output "organizational_unit_ids" {
  value = module.organizations.organizational_unit_ids
}
```

---

## Commercial + GovCloud Account Creation (Planned)

Currently, this module only manages existing AWS accounts. In the future, support may be added for creating new Commercial + GovCloud account pairs using the [`create_govcloud`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account#create_govcloud) option. The `create_govcloud` field is included in the account parameters for future compatibility, but is not used at this time.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.management"></a> [aws.management](#provider\_aws.management) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_organizations_account.commercial](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_account.govcloud](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_organizational_unit.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_parameters"></a> [aws\_account\_parameters](#input\_aws\_account\_parameters) | Map of AWS account parameters to be managed by the module.<br/><br/>- Each key is an AWS account ID (12-digit string).<br/>- Each value is an object with:<br/>    - email:         The primary email address for the AWS account.<br/>    - lifecycle:     The lifecycle tag for the account (e.g., "prod", "nonprod").<br/>    - name:          The display name for the account.<br/>    - ou:            The Organizational Unit (OU) name to assign the account to, or "Root" for management account.<br/>    - tags:          (Optional) Additional tags to apply to the account.<br/>    - create\_govcloud: (Optional, future use) Whether to create a GovCloud account paired with this commercial account. Currently ignored.<br/><br/>Example:<br/>  {<br/>    "111111111111" = {<br/>      email          = "management@example.com"<br/>      lifecycle      = "prod"<br/>      name           = "Management"<br/>      ou             = "Root"               # Management account stays at org root per AWS SRA<br/>      tags           = { Environment = "Production" }<br/>      create\_govcloud = false<br/>    }<br/>    "222222222222" = {<br/>      email          = "workload@example.com"<br/>      lifecycle      = "prod"<br/>      name           = "Workload"<br/>      ou             = "Workloads\_Prod"     # Member accounts go in OUs<br/>      tags           = { Environment = "Production" }<br/>      create\_govcloud = false<br/>    }<br/>  }<br/><br/>Notes:<br/>  - All accounts must already exist; this module does not create new accounts yet.<br/>  - The management account should use ou = "Root" per AWS Security Reference Architecture.<br/>  - Member account 'ou' values must correspond to OUs created by the module.<br/>  - The 'create\_govcloud' field is reserved for future support of commercial+GovCloud account creation. | <pre>map(object({<br/>    email           = string<br/>    lifecycle       = string<br/>    name            = string<br/>    ou              = string<br/>    tags            = optional(map(string), {})<br/>    create_govcloud = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_aws_organization_id"></a> [aws\_organization\_id](#input\_aws\_organization\_id) | ID for existing AWS Govcloud Organization. If not provided, the module will create a new organization. | `string` | `null` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | A map of tags to add to all resources. These are merged with any resource-specific tags. | `map(string)` | <pre>{<br/>  "Owner": "stigian",<br/>  "Project": "demo",<br/>  "Repository": "https://github.com/stigian/terraform-aws-cspm"<br/>}</pre> | no |
| <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units) | Map of Organizational Unit (OU) names to their attributes.<br/><br/>Example:<br/>  {<br/>    Security = {<br/>      lifecycle = "prod"<br/>      tags      = { Owner = "SecurityTeam" }<br/>    }<br/>    Workloads\_Prod = {<br/>      lifecycle = "prod"<br/>      tags      = {}<br/>    }<br/>  }<br/><br/>- The key is the OU name.<br/>- The value is an object with:<br/>    - lifecycle: (string) The lifecycle tag for the OU (e.g., "prod", "nonprod").<br/>    - tags:      (optional map) Additional tags for the OU. | <pre>map(object({<br/>    lifecycle = string<br/>    tags      = optional(map(string), {})<br/>  }))</pre> | <pre>{<br/>  "Infrastructure_Prod": {<br/>    "lifecycle": "prod",<br/>    "tags": {}<br/>  },<br/>  "Infrastructure_Test": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  },<br/>  "Policy_Staging": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  },<br/>  "Sandbox": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  },<br/>  "Security": {<br/>    "lifecycle": "prod",<br/>    "tags": {}<br/>  },<br/>  "Suspended": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  },<br/>  "Workloads_Prod": {<br/>    "lifecycle": "prod",<br/>    "tags": {}<br/>  },<br/>  "Workloads_Test": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  }<br/>}</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | Name of the project or application. Used for naming resources. | `string` | `"demo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id_map"></a> [account\_id\_map](#output\_account\_id\_map) | Map of account names to account IDs for use by the SSO submodule. |
| <a name="output_account_organizational_units"></a> [account\_organizational\_units](#output\_account\_organizational\_units) | Map of account IDs to their OU names. |
| <a name="output_account_resources"></a> [account\_resources](#output\_account\_resources) | Map of account resources (abstracts commercial vs govcloud partition differences) |
| <a name="output_aws_partition"></a> [aws\_partition](#output\_aws\_partition) | The AWS partition (aws or aws-us-gov) where the organization is running. |
| <a name="output_global_tags"></a> [global\_tags](#output\_global\_tags) | Global tags for use by submodules. |
| <a name="output_is_govcloud"></a> [is\_govcloud](#output\_is\_govcloud) | Boolean indicating if the organization is running in AWS GovCloud. |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | The AWS Organization ID. |
| <a name="output_organizational_unit_ids"></a> [organizational\_unit\_ids](#output\_organizational\_unit\_ids) | Map of OU names to their AWS Organization Unit IDs. |
| <a name="output_project"></a> [project](#output\_project) | Project name for use by submodules. |
<!-- END_TF_DOCS -->