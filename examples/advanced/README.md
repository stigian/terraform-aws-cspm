# Advanced CSPM Example with YAML Configuration

This example demonstrates a comprehensive DoD Zero Trust CSPM deployment using YAML-driven configuration:

- **YAML Configuration**: Structured configuration files for accounts and OUs
- **Organizations Module**: Account management with flexible OU structure
- **Control Tower Module**: Landing zone with compliance guardrails  
- **SSO Module**: Compliance-standardized IAM Identity Center configuration
- **Cross-Account Security Services**: GuardDuty, Security Hub, Inspector2, Detective

## Architecture

```
config/
├── accounts/           # Account definitions by category
│   ├── foundation.yaml # Management account
│   ├── security.yaml   # Log archive & audit accounts
│   ├── infrastructure.yaml # Network and shared services accounts
│   └── workloads.yaml  # Application workload accounts
└── organizational-units/
    ├── foundation.yaml # Root and core OUs
    ├── infrastructure.yaml # Network and shared services OUs
    └── workloads.yaml  # Application workload OUs
```

**Note**: SSO groups and permission sets are standardized for compliance and cannot be customized via YAML.

## Prerequisites

**CRITICAL**: All AWS accounts must be created via AWS CLI FIRST before running this configuration.

```bash
# Create foundation accounts
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Management" \
  --email "aws-mgmt@yourorg.com" \
  --profile your-management-profile

# Create security accounts  
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Security-LogArchive" \
  --email "aws-logs@yourorg.com" \
  --profile your-management-profile

aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Security-Audit" \
  --email "aws-audit@yourorg.com" \
  --profile your-management-profile

# Create workload accounts as needed...
```

## Configuration

1. **Update YAML files** in the `config/` directory with your actual account information
2. **Configure your AWS profile** for the management account
3. **Update terraform.tfvars** with basic settings
4. **Update the existing admin user ID** in SSO configuration

## Deployment

```bash
# Configure your AWS credentials
export AWS_PROFILE=your-mgmt-profile

# Initialize and deploy
tofu init
tofu plan
tofu apply
```

## YAML Configuration Benefits

- **Organized Structure**: Account and OU configurations grouped logically
- **Easier Management**: Non-technical staff can update account information
- **Version Control**: Track changes to organizational structure over time
- **Scalability**: Easy to add new accounts and OUs
- **Validation**: Built-in validation through structured schema
- **Compliance**: SSO uses standardized, compliance-approved groups and permission sets

## What This Creates

- **AWS Organizations**: Account structure with custom OU hierarchy
- **Control Tower Landing Zone**: With comprehensive compliance guardrails
- **IAM Identity Center**: Standardized SSO with compliance-approved groups and permission sets
- **Cross-Account Security**: Centralized security services across all accounts
- **Account Import**: Manages existing accounts without disruption

## SSO Groups and Access

The SSO module creates standardized, compliance-approved groups:

- **aws_admin**: Full administrative access to all accounts
- **aws_cyber_sec_eng**: Security engineering access with elevated security permissions
- **aws_sec_auditor**: Security auditor access with read-only permissions

These groups and their permission sets are standardized for DoD compliance and cannot be customized.

## Extending the Configuration

To add new accounts:
1. Add account definition to appropriate YAML file in `config/accounts/`
2. Create the account via AWS CLI first
3. Run `tofu plan` and `tofu apply`

To add new OUs:
1. Add OU definition to appropriate YAML file in `config/organizational-units/`
2. Run `tofu plan` and `tofu apply`
