# Simple CSPM Example

This example demonstrates a basic DoD Zero Trust CSPM deployment with:

- **Organizations Module**: Account management and OU structure
- **Control Tower Module**: Landing zone with compliance guardrails
- **SSO Module**: Basic IAM Identity Center configuration

## Prerequisites

**CRITICAL**: All AWS accounts must be created via AWS CLI FIRST before running this configuration.

```bash
# Create required Control Tower accounts (GovCloud example)
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Management" \
  --email "aws-mgmt@yourorg.com" \
  --profile your-management-profile

aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Security-LogArchive" \
  --email "aws-logs@yourorg.com" \
  --profile your-management-profile

aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Security-Audit" \
  --email "aws-audit@yourorg.com" \
  --profile your-management-profile
```

## Configuration

1. **Update `terraform.tfvars`** with your actual account IDs, names, and emails
2. **Configure your AWS profile** for the management account
3. **Update the existing admin user ID** in the SSO configuration

## Deployment

```bash
# Configure your AWS credentials
export AWS_PROFILE=your-mgmt-profile

# Initialize and deploy
tofu init
tofu plan
tofu apply
```

## What This Creates

- **AWS Organizations**: Account structure with SRA-compliant OUs
- **Control Tower Landing Zone**: With audit and log archive accounts
- **IAM Identity Center**: Basic SSO configuration with admin access
- **Account Import**: Manages existing accounts without recreating them

## Next Steps

After deployment, you can:
- Add additional accounts to `aws_account_parameters`
- Extend OUs by adding to `organizational_units`
- Configure additional SSO groups and permission sets
- Add security services (GuardDuty, Security Hub, etc.)
