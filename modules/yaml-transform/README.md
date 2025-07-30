# YAML Transform Module

This module transforms YAML configuration files into Terraform-compatible data structures for use with the organizations, sso, and controltower modules. It serves as the central data transformation engine that enables user-friendly YAML configuration while maintaining resource key compatibility for existing infrastructure.

## Features

- **YAML-Based Configuration**: Human-readable configuration files
- **Central Data Transformation**: Single source of truth for all module data
- **Resource Key Preservation**: Maintains existing Terraform resource keys to prevent infrastructure destruction
- **Enhanced Data Structures**: Provides account mappings, type groupings, and Control Tower integrations
- **Built-in Validation**: Comprehensive validation against SRA account types and configuration standards
- **Multi-Module Support**: Prepares data for organizations, SSO, Control Tower, and security services modules

## Directory Structure

```
config/
├── accounts/
│   ├── foundation.yaml     # Management account
│   ├── security.yaml       # Log archive & audit accounts
│   ├── infrastructure.yaml # Network & shared services accounts
│   └── workloads.yaml      # Application workload accounts
└── organizational-units/
    ├── foundation.yaml     # Core OUs (Security, Policy_Staging, etc.)
    ├── infrastructure.yaml # Infrastructure OUs
    └── workloads.yaml      # Workload OUs
```

**Note**: SSO configuration is not customizable via YAML as it uses compliance-standardized groups and permission sets.

## Usage

```hcl
module "yaml_transform" {
  source = "../modules/yaml-transform"
  
  config_directory = "${path.module}/config"
  project         = "myorg"
  global_tags     = {
    Environment = "production"
    Owner       = "platform-team"
  }
  enable_validation = true
}

# Organizations module
module "organizations" {
  source = "../modules/organizations"
  
  project                = module.yaml_transform.project
  aws_account_parameters = module.yaml_transform.aws_account_parameters
  organizational_units   = module.yaml_transform.organizational_units
  global_tags           = module.yaml_transform.global_tags
}

# SSO module  
module "sso" {
  source = "../modules/sso"
  
  project              = module.yaml_transform.project
  account_id_map       = module.yaml_transform.account_id_map
  account_role_mapping = module.yaml_transform.account_role_mapping
  global_tags          = module.yaml_transform.global_tags
}

# Control Tower module
module "controltower" {
  source = "../modules/controltower" 
  
  management_account_id  = module.yaml_transform.management_account_id
  log_archive_account_id = module.yaml_transform.log_archive_account_id
  audit_account_id       = module.yaml_transform.audit_account_id
}
```

## Enhanced Data Outputs

The module provides several enhanced data structures for downstream modules:

### Core Configuration
- `aws_account_parameters` - Account data for organizations module
- `organizational_units` - OU data for organizations module  
- `global_tags` - Merged project and user-defined tags

### SSO Integration
- `account_id_map` - Account name → Account ID mapping
- `account_role_mapping` - Account name → Account type mapping

### Control Tower Integration  
- `management_account_id` - Extracted management account ID
- `log_archive_account_id` - Extracted log archive account ID
- `audit_account_id` - Extracted audit account ID

### Security Services Integration
- `accounts_by_type` - Accounts grouped by SRA account type
- `raw_account_configs` - Original YAML data for advanced use cases

## Configuration Format

### Account Configuration Example

```yaml
# config/accounts/foundation.yaml
management_account:
  account_id: "123456789012"
  account_name: "MyOrg-Management"
  email: "aws-management@myorg.com"
  account_type: management  # Must match SRA account types
  ou: Root                  # Organizational Unit placement
  lifecycle: prod           # Must be 'prod' or 'nonprod'
  additional_tags:
    Owner: "Central IT"
    Purpose: "Organization Management"
  create_govcloud: false    # Optional GovCloud creation
```

### Organizational Unit Example

```yaml
# config/organizational-units/foundation.yaml
Security:
  lifecycle: prod
  additional_tags:
    Purpose: "Security"
    Compliance: "Required"

Policy_Staging:
  lifecycle: nonprod
  additional_tags:
    Purpose: "Policy Testing"
```

## Key Benefits

1. **Resource Key Preservation**: Maintains existing Terraform resource keys to prevent infrastructure destruction
2. **Centralized Transformation**: Single module handles all data preparation for downstream modules
3. **SRA Compliance**: Built-in validation against AWS Security Reference Architecture patterns
4. **User-Friendly**: YAML is easier to read and write than complex HCL structures
5. **Version Control**: Better diff visualization and conflict resolution
6. **Enhanced Integration**: Provides specialized data structures for SSO, Control Tower, and security services
7. **Scalable Account Management**: Easy to add new accounts as your organization grows

## Adding New Accounts

The YAML configuration supports adding multiple accounts of each type. See the **[Account Management Guide](../../docs/account-management-guide.md)** for detailed instructions on:

- Adding new workload accounts
- Creating infrastructure accounts  
- Managing account lifecycle
- Troubleshooting common issues
- Best practices and naming conventions

## Validation

The module includes comprehensive validation when `enable_validation = true`:

- Account ID format (12-digit validation)
- Email format validation
- Lifecycle values ('prod' or 'nonprod' only)
- Account type validation against SRA account types
- OU lifecycle consistency

Validation errors are reported clearly with specific details about configuration issues.
