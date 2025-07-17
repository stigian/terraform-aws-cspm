# AWS SSO Module

This Terraform module manages AWS IAM Identity Center (formerly AWS SSO) integration with optional Microsoft Entra ID (formerly Azure AD) federation. It creates IAM Identity Center permission sets, groups, and account assignments based on common AWS personas and security roles.

---

## Features

- **AWS IAM Identity Center Management**: Creates permission sets, groups, and account assignments
- **Optional Entra ID Integration**: Federates with Microsoft Entra ID for centralized identity management
- **Persona-Based Security Groups**: Pre-configured groups aligned with AWS best practices
- **Flexible Account Assignments**: Automatically assigns groups to accounts based on account type
- **Control Tower Compatibility**: Automatically detects and works with AWS Control Tower
- **Conditional Resource Creation**: Enable/disable features based on your environment needs

---

## Architecture

This module supports two primary deployment patterns:

1. **AWS-Only**: Use AWS IAM Identity Center without external identity federation
2. **Hybrid**: Integrate with Microsoft Entra ID for federated authentication

### Security Groups (Personas)

The module creates the following predefined security groups based on common AWS personas:

- **aws-admin**: Administrator access (AdministratorAccess)
- **aws-cyber-sec-eng**: Cybersecurity engineering (PowerUserAccess with planned custom policy)
- **aws-net-admin**: Network administration (NetworkAdministrator)
- **aws-power-user**: Power user access (PowerUserAccess)
- **aws-sec-auditor**: Security auditing (SecurityAudit)
- **aws-sys-admin**: System administration (SystemAdministrator)

### Account Assignment Strategy

Groups are automatically assigned to accounts based on AWS Security Reference Architecture (SRA) account types:

#### Core Foundation Accounts
- **management**: aws-admin only (organization-level administrative access)
- **log_archive**: aws-admin, aws-cyber-sec-eng, aws-sec-auditor (security logging oversight)
- **audit**: aws-admin, aws-cyber-sec-eng, aws-sec-auditor (compliance and audit functions)

#### Connectivity & Network Accounts
- **network**: All groups (comprehensive infrastructure and connectivity management)
- **shared_services**: aws-admin, aws-sys-admin, aws-net-admin, aws-power-user (shared infrastructure)

#### Security Accounts
- **security_tooling**: aws-admin, aws-cyber-sec-eng, aws-sec-auditor (dedicated security tools)
- **backup**: aws-admin, aws-sys-admin (backup and recovery management)

#### Workload Accounts
- **workload_prod**: aws-admin, aws-sys-admin, aws-power-user (production workload management)
- **workload_nonprod**: All groups (development, testing, and staging environments)
- **workload_sandbox**: All groups (experimental and proof-of-concept work)

#### Future Account Types
- **deployment**: aws-admin, aws-sys-admin, aws-power-user (CI/CD and deployment automation)
- **data**: aws-admin, aws-power-user, aws-sec-auditor (data analytics and governance)

---

## AWS Security Reference Architecture (SRA) Support

This module is designed to align with the AWS Security Reference Architecture (SRA) account taxonomy and organizational structure. The module supports the following standardized account types:

### Core Foundation Accounts (Required by AWS SRA)

| Account Type | Description | OU Placement | GovCloud |
|--------------|-------------|--------------|----------|
| `management` | Organization management, billing, and governance | Root | No |
| `log_archive` | Centralized logging and long-term log storage | Security | Yes |
| `audit` | Security audit, compliance monitoring, and reporting | Security | Yes |

### Connectivity & Network Accounts

| Account Type | Description | OU Placement | GovCloud |
|--------------|-------------|--------------|----------|
| `network` | Central network connectivity (Transit Gateway, Direct Connect) | Infrastructure_Prod | Yes |
| `shared_services` | Shared infrastructure services (DNS, monitoring, tooling) | Infrastructure_Prod | Yes |

### Security Accounts

| Account Type | Description | OU Placement | GovCloud |
|--------------|-------------|--------------|----------|
| `security_tooling` | Security tools, SIEM, threat detection | Security | Yes |
| `backup` | Centralized backup, disaster recovery | Security | Yes |

### Workload Accounts

| Account Type | Description | OU Placement | GovCloud |
|--------------|-------------|--------------|----------|
| `workload_prod` | Production workloads and applications | Workloads_Prod | Yes |
| `workload_nonprod` | Development, testing, and staging environments | Workloads_Test | Yes |
| `workload_sandbox` | Experimental and proof-of-concept environments | Sandbox | No |

### Future Account Types (Expansion Ready)

| Account Type | Description | OU Placement | GovCloud |
|--------------|-------------|--------------|----------|
| `deployment` | CI/CD pipelines, build systems, deployment automation | Infrastructure_Prod | Yes |
| `data` | Data lakes, analytics platforms, big data workloads | Workloads_Prod | Yes |

The module includes comprehensive validation to ensure account configurations follow AWS SRA best practices and provides pre-defined configurations for common deployment patterns.

---

## Usage

### Basic AWS-Only Configuration

```hcl
module "sso" {
  source = "./modules/sso"

  project               = "my-project"
  enable_sso_management = true
  enable_entra_integration = false

  # AWS SRA standard account mapping
  account_role_mapping = {
    management = {
      account_name = "org-management"
      email       = "aws-management@organization.com"
      ou_path     = "Root"
    }
    log_archive = {
      account_name = "security-log-archive"
      email       = "aws-log-archive@organization.com"
      ou_path     = "Security"
    }
    audit = {
      account_name = "security-audit"
      email       = "aws-audit@organization.com"
      ou_path     = "Security"
    }
    network = {
      account_name = "infrastructure-network"
      email       = "aws-network@organization.com"
      ou_path     = "Infrastructure_Prod"
    }
  }

  global_tags = {
    Project     = "my-project"
    Environment = "production"
  }
}
```

### Full Configuration with Entra ID Integration

```hcl
module "sso" {
  source = "./modules/sso"

  project                      = "my-project"
  enable_sso_management        = true
  enable_entra_integration     = true
  auto_detect_control_tower    = true

  # Entra ID Configuration
  azuread_environment          = "usgovernment"  # or "global"
  entra_tenant_id             = "your-tenant-id"
  saml_notification_emails    = ["admin@example.com"]
  login_url                   = "https://your-org.awsapps.com/start"
  redirect_uris               = ["https://signin.aws.amazon.com/saml"]
  identifier_uri              = "https://signin.aws.amazon.com/saml"
  entra_group_admin_object_ids = ["admin-user-object-id"]

  # AWS SRA comprehensive account mapping
  account_role_mapping = {
    management = {
      account_name = "org-management"
      email       = "aws-management@organization.com"
      ou_path     = "Root"
    }
    log_archive = {
      account_name = "security-log-archive"
      email       = "aws-log-archive@organization.com"
      ou_path     = "Security"
    }
    audit = {
      account_name = "security-audit"
      email       = "aws-audit@organization.com"
      ou_path     = "Security"
    }
    network = {
      account_name = "infrastructure-network"
      email       = "aws-network@organization.com"
      ou_path     = "Infrastructure_Prod"
    }
    shared_services = {
      account_name = "infrastructure-shared-services"
      email       = "aws-shared-services@organization.com"
      ou_path     = "Infrastructure_Prod"
    }
    security_tooling = {
      account_name = "security-tooling"
      email       = "aws-security-tools@organization.com"
      ou_path     = "Security"
    }
    workload_prod = {
      account_name = "workload-production"
      email       = "aws-workload-prod@organization.com"
      ou_path     = "Workloads_Prod"
    }
    workload_nonprod = {
      account_name = "workload-development"
      email       = "aws-workload-dev@organization.com"
      ou_path     = "Workloads_Test"
    }
  }

  global_tags = {
    Project     = "my-project"
    Environment = "production"
  }
}
```

### Integration with Organizations Module

```hcl
module "organizations" {
  source = "./modules/organizations"
  
  project = "my-project"
  # ... other organizations config
}

module "sso" {
  source = "./modules/sso"

  project              = var.project
  account_role_mapping = module.organizations.account_role_mapping  # Pass account mapping from organizations
  
  enable_sso_management    = true
  enable_entra_integration = true
  
  # ... other SSO config
}
```

### Using Account Role Mapping

The module uses the `account_role_mapping` variable to map accounts to their AWS SRA account types:

```hcl
# Example: Custom configuration for different account types
account_role_mapping = {
  # Core Foundation Accounts
  management = {
    account_name = "org-management"
    email       = "aws-management@organization.com"
    ou_path     = "Root"
  }
  log_archive = {
    account_name = "security-log-archive"
    email       = "aws-log-archive@organization.com"
    ou_path     = "Security"
  }
  audit = {
    account_name = "security-audit"
    email       = "aws-audit@organization.com"
    ou_path     = "Security"
  }
  
  # Infrastructure Accounts
  network = {
    account_name = "infrastructure-network"
    email       = "aws-network@organization.com"
    ou_path     = "Infrastructure_Prod"
  }
  shared_services = {
    account_name = "infrastructure-shared-services"
    email       = "aws-shared-services@organization.com"
    ou_path     = "Infrastructure_Prod"
  }
  
  # Workload Accounts
  workload_prod = {
    account_name = "workload-production"
    email       = "aws-workload-prod@organization.com"
    ou_path     = "Workloads_Prod"
  }
  workload_nonprod = {
    account_name = "workload-development"
    email       = "aws-workload-dev@organization.com"
    ou_path     = "Workloads_Test"
  }
}
```

---

## Control Tower Integration

When `auto_detect_control_tower` is enabled (default: `true`), the module automatically detects if AWS Control Tower is managing Identity Center and adjusts accordingly:

- If Control Tower is detected, SSO management is automatically disabled
- Entra ID integration can still be enabled for group management
- Manual override is possible by setting `enable_sso_management = false`

---

## Provider Configuration

### Required Providers

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}
```

### AzureAD Provider (Optional)

When `enable_entra_integration = true`, configure the AzureAD provider:

```hcl
provider "azuread" {
  environment = "usgovernment"  # or "global"
  tenant_id   = "your-tenant-id"
}
```

---

## Variable Validation

The module includes comprehensive validation rules:

- **Entra ID Dependencies**: When `enable_entra_integration = true`, all Entra-related variables become required
- **Email Validation**: SAML notification emails must be valid email addresses
- **Environment Validation**: Azure AD environment must be either "global" or "usgovernment"

---

## Outputs

Key outputs for integration with other modules:

- `identity_store_groups`: AWS Identity Store groups
- `permission_sets`: AWS SSO permission sets
- `entra_groups`: Entra ID groups (if enabled)
- `entra_application`: Entra ID application (if enabled)
- `account_assignments`: Account assignment mappings

---

## Security Considerations

- **Least Privilege**: Permission sets use AWS managed policies aligned with job functions
- **Group-Based Access**: All access is group-based, no direct user assignments
- **Session Duration**: 8-hour session duration for all permission sets
- **Administrative Control**: Entra groups have designated owners for governance

---

## Future Enhancements

- Custom IAM policies for specific personas (e.g., cyber security engineering)
- Privileged Identity Management (PIM) integration
- Additional persona-based groups
- Fine-grained permission boundaries
- Automated account creation based on AWS SRA patterns

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| aws | >= 5.0.0 |
| azuread | ~> 3.0.0 |
| random | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0.0 |
| azuread | ~> 3.0.0 |
| random | >= 3.1.0 |

## Resources

| Name | Type |
|------|------|
| aws_identitystore_group.this | resource |
| aws_ssoadmin_account_assignment.this | resource |
| aws_ssoadmin_permission_set.this | resource |
| aws_ssoadmin_managed_policy_attachment.this | resource |
| azuread_application.aws_sso | resource |
| azuread_application_app_role.aws_sso | resource |
| azuread_app_role_assignment.aws_sso | resource |
| azuread_group.aws_sso_groups | resource |
| azuread_group.entra_security_groups | resource |
| azuread_service_principal.aws_sso | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Name of the project or application. Used for naming resources. | `string` | n/a | yes |
| global_tags | A map of tags to add to all resources. These are merged with any resource-specific tags. | `map(string)` | n/a | yes |
| account_role_mapping | Mapping of account role types to account configuration. Supports all AWS SRA account types. | `map(object({account_name=string, email=string, ou_path=string}))` | n/a | yes |
| enable_sso_management | Whether to enable management of AWS IAM Identity Center resources. | `bool` | `true` | no |
| enable_entra_integration | Whether to enable Microsoft Entra ID integration. | `bool` | `false` | no |
| auto_detect_control_tower | Whether to automatically detect if Control Tower is managing Identity Center. | `bool` | `true` | no |
| azuread_environment | Azure AD environment (global or usgovernment). Required when enable_entra_integration is true. | `string` | `null` | no |
| entra_tenant_id | Microsoft Entra tenant ID. Required when enable_entra_integration is true. | `string` | `null` | no |
| saml_notification_emails | List of email addresses for SAML configuration notifications. Required when enable_entra_integration is true. | `list(string)` | `[]` | no |
| login_url | AWS SSO login URL for SAML configuration. Required when enable_entra_integration is true. | `string` | `null` | no |
| redirect_uris | List of redirect URIs for SAML configuration. Required when enable_entra_integration is true. | `list(string)` | `[]` | no |
| identifier_uri | Identifier URI for SAML configuration. Required when enable_entra_integration is true. | `string` | `null` | no |
| entra_group_admin_object_ids | List of user object IDs who will be owners of Entra groups. Required when enable_entra_integration is true. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| identity_store_groups | Map of AWS Identity Store groups created by this module |
| permission_sets | Map of AWS SSO permission sets created by this module |
| entra_groups | Map of Entra ID groups created by this module |
| entra_application | The Entra ID application for AWS SSO integration |
| account_assignments | Map of account assignments created by this module |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 3.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 3.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_identitystore_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group) | resource |
| [aws_ssoadmin_account_assignment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment) | resource |
| [aws_ssoadmin_managed_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment) | resource |
| [aws_ssoadmin_permission_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set) | resource |
| [azuread_app_role_assignment.aws_sso](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_app_role_assignment.user_read_all](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application.aws_sso](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_app_role.aws_sso](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_app_role) | resource |
| [azuread_application_identifier_uri.aws_sso](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_identifier_uri) | resource |
| [azuread_group.aws_sso_groups](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |
| [azuread_group.entra_security_groups](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |
| [azuread_service_principal.aws_sso](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal.msgraph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_token_signing_certificate.aws_sso](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_token_signing_certificate) | resource |
| [random_uuid.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |
| [azuread_application_published_app_ids.well_known](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application_published_app_ids) | data source |
| [azuread_application_template.aws_sso](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application_template) | data source |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id_map"></a> [account\_id\_map](#input\_account\_id\_map) | Mapping of account names to AWS account IDs.<br/><br/>Required account types should include:<br/>  - management: The AWS Organization management account<br/>  - network: Network/connectivity account (for Transit Gateway, etc.)<br/>  - log\_archive: Log aggregation and archive account<br/>  - audit: Security audit account<br/><br/>Example:<br/>  {<br/>    "Management Account" = "111111111111"<br/>    "Network Account"    = "222222222222"<br/>    "Log Archive"        = "333333333333"<br/>    "Security Audit"     = "444444444444"<br/>  } | `map(string)` | n/a | yes |
| <a name="input_account_role_mapping"></a> [account\_role\_mapping](#input\_account\_role\_mapping) | Mapping of account names to their AWS SRA account types for SSO group assignments.<br/><br/>Each key should match an account name from account\_id\_map.<br/>Each value must be one of the standard AWS SRA account types:<br/><br/>**Core Foundation Accounts (Required):**<br/>- management: Organization management account (stays at org root)<br/>- log\_archive: Centralized logging and long-term log storage<br/>- audit: Security audit and compliance account<br/>-<br/>**Connectivity & Network Accounts:**<br/>- network: Central network connectivity (Transit Gateway, Direct Connect, etc.)<br/>- shared\_services: Shared infrastructure services (DNS, monitoring, etc.)<br/><br/>**Security Accounts:**<br/>- security\_tooling: Security tools and SIEM (often combined with audit)<br/>- backup: Centralized backup and disaster recovery<br/><br/>**Workload Accounts:**<br/>- workload\_prod: Production workloads<br/>- workload\_nonprod: Non-production workloads (dev, test, staging)<br/>- workload\_sandbox: Experimental and sandbox environments<br/><br/>**Future Account Types (for reference):**<br/>- deployment: CI/CD and deployment tools<br/>- data: Data lakes, analytics, and big data workloads<br/><br/>Example:<br/>  {<br/>    "MyOrg Management"     = "management"<br/>    "Production Network"   = "network" <br/>    "Security Log Archive" = "log\_archive"<br/>    "Compliance Audit"     = "audit"<br/>    "ACME-prod-workload"   = "workload\_prod"<br/>    "ACME-dev-workload"    = "workload\_nonprod"<br/>  } | `map(string)` | `{}` | no |
| <a name="input_auto_detect_control_tower"></a> [auto\_detect\_control\_tower](#input\_auto\_detect\_control\_tower) | Whether to automatically detect if Control Tower is managing Identity Center and disable SSO management accordingly. | `bool` | `true` | no |
| <a name="input_azuread_environment"></a> [azuread\_environment](#input\_azuread\_environment) | Azure AD environment, either global or usgovernment. | `string` | `"usgovernment"` | no |
| <a name="input_enable_entra_integration"></a> [enable\_entra\_integration](#input\_enable\_entra\_integration) | Whether to enable Microsoft Entra ID integration. Set to false to use only AWS IAM Identity Center without Entra. | `bool` | `false` | no |
| <a name="input_enable_sso_management"></a> [enable\_sso\_management](#input\_enable\_sso\_management) | Whether to enable management of AWS IAM Identity Center resources.<br/><br/>Set to false if:<br/>- Control Tower is managing Identity Center<br/>- Identity Center is managed elsewhere<br/>- You only want Entra ID groups without AWS SSO integration<br/><br/>When false, only Entra ID resources (if enabled) will be created.<br/><br/>Note: The module will automatically detect if Control Tower is managing<br/>Identity Center and adjust accordingly. | `bool` | `true` | no |
| <a name="input_entra_group_admin_object_ids"></a> [entra\_group\_admin\_object\_ids](#input\_entra\_group\_admin\_object\_ids) | List of user object IDs for group administrators / owners. Required only if enable\_entra\_integration is true. | `list(string)` | `[]` | no |
| <a name="input_entra_tenant_id"></a> [entra\_tenant\_id](#input\_entra\_tenant\_id) | Entra Tenant ID. Required only if enable\_entra\_integration is true. | `string` | `null` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | A map of tags to add to all resources. These are merged with any resource-specific tags. | `map(string)` | n/a | yes |
| <a name="input_identifier_uri"></a> [identifier\_uri](#input\_identifier\_uri) | Issuer URL from IAM Identity Center. Required only if enable\_entra\_integration is true. | `string` | `null` | no |
| <a name="input_login_url"></a> [login\_url](#input\_login\_url) | AWS access portal sign-in URL from IAM Identity Center. Required only if enable\_entra\_integration is true. | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Name of the project or application. Used for naming resources. | `string` | n/a | yes |
| <a name="input_redirect_uris"></a> [redirect\_uris](#input\_redirect\_uris) | Assertion Consumer Service (ACS) URL(s) from IAM Identity Center. Required only if enable\_entra\_integration is true. | `list(string)` | `[]` | no |
| <a name="input_saml_notification_emails"></a> [saml\_notification\_emails](#input\_saml\_notification\_emails) | List of email addresses to receive SAML certificate expiration notifications. Required only if enable\_entra\_integration is true. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_assignments"></a> [account\_assignments](#output\_account\_assignments) | Map of account assignments created by this module. |
| <a name="output_entra_application"></a> [entra\_application](#output\_entra\_application) | The Entra ID application for AWS SSO integration. |
| <a name="output_entra_groups"></a> [entra\_groups](#output\_entra\_groups) | Map of Entra ID groups created by this module. |
| <a name="output_identity_store_groups"></a> [identity\_store\_groups](#output\_identity\_store\_groups) | Map of AWS Identity Store groups created by this module. |
| <a name="output_permission_sets"></a> [permission\_sets](#output\_permission\_sets) | Map of AWS SSO permission sets created by this module. |
<!-- END_TF_DOCS -->