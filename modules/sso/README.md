<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_identitystore_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group) | resource |
| [aws_identitystore_group_membership.initial_admin_memberships](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group_membership) | resource |
| [aws_identitystore_user.initial_admins](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_user) | resource |
| [aws_ssoadmin_account_assignment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment) | resource |
| [aws_ssoadmin_managed_policy_attachment.detective_fullaccess](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment) | resource |
| [aws_ssoadmin_managed_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment) | resource |
| [aws_ssoadmin_permission_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id_map"></a> [account\_id\_map](#input\_account\_id\_map) | Mapping of account names to AWS account IDs.<br/><br/>CONTROL TOWER REQUIREMENTS (if using Control Tower):<br/>The following account types are MANDATORY and must match your Organizations module:<br/>  - management: The AWS Organization management account (AccountType = "management")<br/>  - log\_archive: Log aggregation and archive account (AccountType = "log\_archive")<br/>  - audit: Security audit account (AccountType = "audit")<br/><br/>Additional recommended account types:<br/>  - network: Network/connectivity account (for Transit Gateway, etc.)<br/>  - shared\_services: Shared infrastructure services<br/><br/>Example:<br/>  {<br/>    "YourCorp-Management"       = "123456789012"   # REQUIRED for Control Tower<br/>    "YourCorp-Security-Logs"    = "234567890123"   # REQUIRED for Control Tower<br/>    "YourCorp-Security-Audit"   = "345678901234"   # REQUIRED for Control Tower<br/>    "YourCorp-Network-Hub"      = "456789012345"   # Optional<br/>    "YourCorp-Workload-Prod1"   = "567890123456"   # Optional<br/>  }<br/><br/>NOTE: Account names here must match the 'name' field in your aws\_account\_parameters | `map(string)` | n/a | yes |
| <a name="input_account_role_mapping"></a> [account\_role\_mapping](#input\_account\_role\_mapping) | Mapping of account names to their AWS SRA account types for SSO group assignments.<br/><br/>Each key should match an account name from account\_id\_map.<br/>Each value must be one of the standard AWS SRA account types.<br/><br/>**CONTROL TOWER REQUIRED ACCOUNTS:**<br/>- management: Organization management account (REQUIRED - AccountType = "management")<br/>- log\_archive: Centralized logging and log storage (REQUIRED - AccountType = "log\_archive")<br/>- audit: Security audit and compliance (REQUIRED - AccountType = "audit")<br/><br/>**SRA-Recommended Security OU Accounts:**<br/>- security\_tooling: Security tools, SIEM, and scanning infrastructure<br/><br/>**SRA-Recommended Infrastructure OU Accounts:**<br/>- network: Central network connectivity (Transit Gateway, Direct Connect, etc.)<br/>- shared\_services: Shared infrastructure services (DNS, monitoring, etc.)<br/><br/>**SRA-Recommended Workloads OU Accounts:**<br/>- workload: Application workload accounts (organize by environment or application per SRA)<br/><br/>Example (showing Control Tower + SRA recommended structure):<br/>  {<br/>    "YourCorp-Management"           = "management"        # REQUIRED - Root OU<br/>    "YourCorp-Security-LogArchive"  = "log\_archive"       # REQUIRED - Security OU<br/>    "YourCorp-Security-Audit"       = "audit"            # REQUIRED - Security OU<br/>    "YourCorp-Security-Tooling"     = "security\_tooling" # Security OU<br/>    "YourCorp-Infrastructure-Network" = "network"        # Infrastructure OU<br/>    "YourCorp-Infrastructure-Shared"  = "shared\_services" # Infrastructure OU<br/>    "YourCorp-Workload-App1-Prod"   = "workload"         # Workloads OU<br/>  }<br/><br/>NOTE: Account names must match exactly with account\_id\_map keys | `map(string)` | `{}` | no |
| <a name="input_auto_detect_control_tower"></a> [auto\_detect\_control\_tower](#input\_auto\_detect\_control\_tower) | Whether to automatically detect if Control Tower is managing Identity Center and disable SSO management accordingly. | `bool` | `true` | no |
| <a name="input_enable_sso_management"></a> [enable\_sso\_management](#input\_enable\_sso\_management) | Whether to enable management of AWS IAM Identity Center resources.<br/><br/>Set to false if:<br/>- Control Tower is managing Identity Center<br/>- Identity Center is managed elsewhere<br/>- You only want Entra ID groups without AWS SSO integration<br/><br/>When false, only Entra ID resources (if enabled) will be created.<br/><br/>Note: The module will automatically detect if Control Tower is managing<br/>Identity Center and adjust accordingly. | `bool` | `true` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Tags applied to all resources created by this module. | `map(string)` | <pre>{<br/>  "ManagedBy": "opentofu"<br/>}</pre> | no |
| <a name="input_initial_admin_users"></a> [initial\_admin\_users](#input\_initial\_admin\_users) | List of admin users to create in AWS IAM Identity Center (optional).<br/><br/>Each user object should contain:<br/>- user\_name: Unique username for SSO login (e.g., "john.doe" or "admin")<br/>- display\_name: Human-readable display name (e.g., "John Doe")<br/>- email: Primary email address for the user<br/>- given\_name: First name<br/>- family\_name: Last name<br/>- admin\_level: Level of admin access ("full" or "security")<br/>  - "full": Gets aws\_admin group (AdministratorAccess to all accounts)<br/>  - "security": Gets aws\_cyber\_sec\_eng and aws\_sec\_auditor groups (security-focused access)<br/><br/>Example:<br/>  [<br/>    {<br/>      user\_name    = "john.doe"<br/>      display\_name = "John Doe"<br/>      email        = "john.doe@your-company.com"<br/>      given\_name   = "John"<br/>      family\_name  = "Doe"<br/>      admin\_level  = "full"<br/>    }<br/>  ] | <pre>list(object({<br/>    user_name    = string<br/>    display_name = string<br/>    email        = string<br/>    given_name   = string<br/>    family_name  = string<br/>    admin_level  = string<br/>  }))</pre> | `[]` | no |
| <a name="input_project"></a> [project](#input\_project) | Name of the project or application. Used for resource naming and tagging. | `string` | `"CnScca"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_assignments"></a> [account\_assignments](#output\_account\_assignments) | Map of account assignments created by this module. |
| <a name="output_control_tower_detected"></a> [control\_tower\_detected](#output\_control\_tower\_detected) | Boolean indicating if Control Tower was detected managing the organization. |
| <a name="output_identity_store_groups"></a> [identity\_store\_groups](#output\_identity\_store\_groups) | Map of AWS Identity Store groups created by this module. |
| <a name="output_permission_sets"></a> [permission\_sets](#output\_permission\_sets) | Map of AWS SSO permission sets created by this module. |
| <a name="output_sra_account_types"></a> [sra\_account\_types](#output\_sra\_account\_types) | Map of SRA account types with their configurations. |
| <a name="output_sso_management_enabled"></a> [sso\_management\_enabled](#output\_sso\_management\_enabled) | Boolean indicating if SSO management is enabled (may be disabled due to Control Tower detection). |
<!-- END_TF_DOCS -->