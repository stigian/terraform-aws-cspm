# CSPM Examples

Live deployment configurations for the DoD Zero Trust CSPM module.

## Configuration Approach

This directory uses **YAML-based configuration** for cleaner, more maintainable account management.

### Files Structure
```
examples/
├── main.tf                    # Main module configuration
├── terraform.tfvars         # Basic variables (project, region, etc.)
├── config/
│   ├── accounts/            # Account definitions by type
│   │   ├── foundation.yaml  # Management account
│   │   ├── security.yaml    # Log archive & audit
│   │   ├── infrastructure.yaml # Network accounts
│   │   └── workloads.yaml   # Application accounts
│   └── organizational-units/ # Custom OU definitions
└── dependencies/            # IAM roles and prerequisites
```

## Quick Start

### 1. Prerequisites (CRITICAL)
**Create AWS accounts via CLI first** - module only manages existing accounts:

```bash
# GovCloud example
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Management" \
  --email "aws-mgmt@yourorg.com" \
  --profile your-management-profile
```

### 2. Configure Accounts
Update YAML files in `config/accounts/` with your actual account IDs, names, and emails.

### 3. Deploy
```bash
export AWS_PROFILE=your-mgmt-profile
tofu init
tofu validate
tofu plan      # Should show account imports and OU placements
tofu apply
```

## Adding Accounts

**Complete Guide**: See [Account Management Guide](../docs/account-management-guide.md)

Key steps: Create account via CLI → Add to YAML config → Deploy with `tofu apply`

## Troubleshooting

### Common Issues
1. **Account Import Failures**: Verify account IDs match CLI creation exactly
2. **OU Placement Errors**: Check lifecycle matches OU name (Infrastructure_Prod vs Infrastructure_NonProd)
3. **Provider Issues**: Ensure AWS profile has management account access

### Getting Help
- [Account Management Guide](../docs/account-management-guide.md) - Comprehensive documentation
- [Integration Strategy](../docs/integration-strategy.md) - Architecture overview
- [Main README](../README.md) - Module overview and quick start

## Architecture

This configuration implements:
- **Organizations Module**: Account management and OU structure (AWS SRA)
- **SSO Module**: IAM Identity Center with standardized permission sets
- **Control Tower Module**: Landing zone with compliance guardrails
- **Security Services** (future): GuardDuty, Security Hub, Inspector2, etc.

**Target**: DISA SCCA-compliant cloud-native architecture for DoD Zero Trust implementation.
