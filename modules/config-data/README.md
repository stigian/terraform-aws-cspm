# Config-Data Module

This module transforms YAML configuration files into Terraform-compatible data structures for use with the organizations, sso, and controltower modules. It enables a user-friendly configuration approach that separates logical account definitions from complex Terraform syntax.

## Features

- **YAML-Based Configuration**: Human-readable configuration files
- **Modular Organization**: Separate files for accounts, OUs, and SSO settings
- **Automatic Processing**: Transforms YAML into module-compatible formats
- **Validation**: Built-in validation for configuration consistency
- **Version Control Friendly**: Small, focused files that are easy to review and maintain

## Directory Structure

```
config/
├── accounts/
│   ├── foundation.yaml     # Management account
│   ├── security.yaml       # Log archive & audit accounts
│   ├── infrastructure.yaml # Network & shared services accounts
│   └── workloads.yaml      # Application workload accounts
├── organizational-units/
│   ├── foundation.yaml     # Core OUs (Security, Policy_Staging, etc.)
│   ├── infrastructure.yaml # Infrastructure OUs
│   └── workloads.yaml      # Workload OUs
└── sso/
    ├── groups.yaml         # SSO group definitions
    └── assignments.yaml    # Account-to-group assignments
```

## Usage

```hcl
module "config_data" {
  source = "../modules/config-data"
  
  config_directory = "${path.module}/config"
  project         = "myorg"
  global_tags     = {
    Environment = "production"
    Owner       = "platform-team"
  }
}

module "organizations" {
  source = "../modules/organizations"
  
  project                = module.config_data.project
  aws_account_parameters = module.config_data.aws_account_parameters
  organizational_units   = module.config_data.organizational_units
  global_tags           = module.config_data.global_tags
}
```

## Configuration Format

### Account Configuration Example

```yaml
# config/accounts/foundation.yaml
management_account:
  account_id: "123456789012"
  account_name: "MyOrg-Management"
  email: "aws-management@myorg.com"
  account_type: management  # Maps to AccountType tag
  ou: Root                  # Organizational Unit
  lifecycle: prod
  additional_tags:
    Owner: "Central IT"
    Purpose: "Organization Management"
```

### Organizational Unit Example

```yaml
# config/organizational-units/foundation.yaml
Security:
  lifecycle: prod
  description: "Security and compliance accounts"
  additional_tags:
    Purpose: "Security"
    Compliance: "Required"
```

### SSO Group Example

```yaml
# config/sso/groups.yaml
groups:
  aws_admin:
    description: "Full administrative access"
    managed_policies:
      - "arn:aws:iam::aws:policy/AdministratorAccess"
```

## Benefits

1. **User-Friendly**: YAML is easier to read and write than HCL
2. **Maintainable**: Small, focused files reduce complexity
3. **Scalable**: Easy to add new accounts and OUs
4. **Version Control**: Better diff visualization and conflict resolution
5. **Documentation**: Inline comments and descriptions
6. **Validation**: Early detection of configuration errors
