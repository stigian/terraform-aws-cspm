# Quick Start Example

This is the simplest possible example to get started with Control Tower.

## Prerequisites

1. Create your AWS accounts using AWS CLI:

```bash
# Create management account
aws organizations create-gov-cloud-account \
  --account-name "MyOrg-Management" \
  --email "mgmt@myorg.com"

# Create log archive account  
aws organizations create-gov-cloud-account \
  --account-name "MyOrg-LogArchive" \
  --email "logs@myorg.com"

# Create audit account
aws organizations create-gov-cloud-account \
  --account-name "MyOrg-Audit" \
  --email "audit@myorg.com"
```

2. Update `main.tf` with your actual account IDs

**Important**: If you need to add workload accounts, use these specific account role types:
- `workload_prod` - for production workloads
- `workload_nonprod` - for development/staging
- `workload_sandbox` - for experimentation

Do NOT use just `"workload"` - it's not a valid AWS SRA account type.

## Deploy

```bash
terraform init
terraform plan
terraform apply
```

That's it! You now have:
- AWS Organizations with proper OU structure
- Control Tower Landing Zone deployed
- SSO configured with security groups
