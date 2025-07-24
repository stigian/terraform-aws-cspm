# Advanced YAML Configuration

This example demonstrates the advanced YAML-based configuration approach using the config-data module. This is ideal for organizations that want:

- Maintainable configuration files
- Better separation of concerns  
- Version control friendly setup
- Inline documentation
- Gradual configuration changes

## Features

- **YAML Configuration**: Human-readable config files instead of complex HCL
- **Modular Setup**: Separate files for accounts, OUs, and SSO
- **Config-Data Module**: Automatically transforms YAML to Terraform data
- **Full Integration**: Works with all three modules (organizations, controltower, sso)

## Configuration Structure

```
config/
├── accounts/
│   ├── foundation.yaml     # Management account
│   ├── security.yaml       # Log archive & audit accounts  
│   ├── infrastructure.yaml # Network accounts
│   └── workloads.yaml      # Application accounts
├── organizational-units/
│   ├── foundation.yaml     # Core OUs
│   ├── infrastructure.yaml # Infrastructure OUs
│   └── workloads.yaml      # Workload OUs
└── sso/
    └── groups.yaml         # SSO groups and permissions
```

## Usage

1. Edit the YAML files in `config/` directory
2. Update `terraform.tfvars` with your organization ID
3. Deploy:

```bash
terraform init
terraform plan
terraform apply
```

## Benefits Over Traditional Approach

- **90% less complexity** in terraform.tfvars
- **Better organization** with focused config files
- **Easier maintenance** - change one file instead of hunting through HCL
- **Self-documenting** with inline comments and clear structure
