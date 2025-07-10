# AWS Organizations Submodule

This Terraform module manages AWS Organizations and Organizational Units (OUs) according to best practices from the [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/architecture.html). It supports creating a new organization or importing an existing one, dynamically creates OUs, and can assign AWS accounts to specific OUs.

---

## Features

- Create or import an AWS Organization
- Dynamically create OUs from a map variable
- Assign AWS accounts to OUs using a flexible map/object structure
- Merge global and resource-specific tags
- Outputs for organization and OU IDs

---

## Usage

```hcl
module "organizations" {
  source = "./modules/organizations"

  project = "my-project"
  tags = {
    Project   = "my-project"
    Owner     = "alice"
    Lifecycle = "prod"
  }

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

  aws_account_parameters = {
    "111111111111" = {
      email     = "account1@example.com"
      lifecycle = "prod"
      name      = "Management"
      ou        = "Security"
      tags      = {
        Environment = "Production"
        Team        = "DevOps"
      }
    }
    "222222222222" = {
      email     = "account2@example.com"
      lifecycle = "nonprod"
      name      = "Workload"
      ou        = "Workloads_Prod"
      tags      = {}
    }
  }

  aws_organization_id = null # or set to existing org ID to import
}
```

---

## GovCloud Note

For existing GovCloud accounts, the `name` and `email` values **must match what is currently set in the AWS Console**. These values cannot be changed from GovCloud; updates must be made from the commercial (linked) account.

---

## Tagging Behavior

- The `tags` variable provides global tags for all resources.
- Resource-specific tags (e.g., per OU or account) are merged with global tags.
- If a tag key exists in both, the resource-specific value takes precedence.

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
| [aws_organizations_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_organizational_unit.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_parameters"></a> [aws\_account\_parameters](#input\_aws\_account\_parameters) | Map of AWS account parameters to be managed by the module.<br/><br/>- Each key is an AWS account ID (12-digit string).<br/>- Each value is an object with:<br/>    - email:      The email address for the AWS account.<br/>                  For existing GovCloud accounts, this must match the current email shown in the AWS Console.<br/>    - lifecycle:  The lifecycle tag for the account (e.g., "prod", "nonprod").<br/>    - name:       The display name for the account.<br/>                  For existing GovCloud accounts, this must match the current account name shown in the AWS Console.<br/>    - ou:         The Organizational Unit (OU) name to assign the account to.<br/>                  Must match one of the OUs defined in 'organizational\_units'.<br/>    - tags:       (Optional) Additional tags to apply to the account.<br/><br/>Example:<br/>  {<br/>    "111111111111" = {<br/>      email     = "account1@example.com"<br/>      lifecycle = "prod"<br/>      name      = "Management"<br/>      ou        = "Security"<br/>      tags      = {<br/>        Environment = "Production"<br/>        Team        = "DevOps"<br/>      }<br/>    }<br/>  }<br/><br/>Notes:<br/>  - For existing GovCloud accounts, the 'name' and 'email' values must match what is currently set in the AWS Console. These values cannot be changed from GovCloud; updates must be made from the commercial (linked) account.<br/>  - The 'ou' value must correspond to an OU created by the module. | <pre>map(object({<br/>    email     = string<br/>    lifecycle = string<br/>    name      = string<br/>    ou        = string<br/>    tags      = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_aws_organization_id"></a> [aws\_organization\_id](#input\_aws\_organization\_id) | ID for existing AWS Govcloud Organization. If not provided, the module will create a new organization. | `string` | `null` | no |
| <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units) | Map of Organizational Unit (OU) names to their attributes.<br/><br/>Example:<br/>  {<br/>    Security = {<br/>      lifecycle = "prod"<br/>      tags      = { Owner = "SecurityTeam" }<br/>    }<br/>    Workloads\_Prod = {<br/>      lifecycle = "prod"<br/>      tags      = {}<br/>    }<br/>  }<br/><br/>- The key is the OU name.<br/>- The value is an object with:<br/>    - lifecycle: (string) The lifecycle tag for the OU (e.g., "prod", "test").<br/>    - tags:      (optional map) Additional tags for the OU. | <pre>map(object({<br/>    lifecycle = string<br/>    tags      = optional(map(string), {})<br/>  }))</pre> | <pre>{<br/>  "Infrastructure_Prod": {<br/>    "lifecycle": "prod",<br/>    "tags": {}<br/>  },<br/>  "Infrastructure_Test": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  },<br/>  "Policy_Staging": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  },<br/>  "Sandbox": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  },<br/>  "Security": {<br/>    "lifecycle": "prod",<br/>    "tags": {}<br/>  },<br/>  "Suspended": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  },<br/>  "Workloads_Prod": {<br/>    "lifecycle": "prod",<br/>    "tags": {}<br/>  },<br/>  "Workloads_Test": {<br/>    "lifecycle": "nonprod",<br/>    "tags": {}<br/>  }<br/>}</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | Name of the project or application. Used for naming resources. | `string` | `"demo"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. These are merged with any resource-specific tags. | `map(string)` | <pre>{<br/>  "Owner": "stigian",<br/>  "Project": "demo",<br/>  "Repository": "https://github.com/stigian/terraform-aws-cspm"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | The AWS Organization ID. |
| <a name="output_organizational_unit_ids"></a> [organizational\_unit\_ids](#output\_organizational\_unit\_ids) | Map of OU names to their AWS Organization Unit IDs. |
<!-- END_TF_DOCS -->