# Account Management Guide

This guide covers how to add, modify, and manage AWS accounts using the YAML configuration approach.

## Overview

The terraform-aws-cspm module uses YAML configuration files to manage AWS accounts in a user-friendly way. Account configurations are organized by type in the `config/accounts/` directory.

## Account Types and Organization

### Account Files Structure
```
config/accounts/
├── foundation.yaml     # Management account (required)
├── security.yaml       # Log archive & audit accounts (required)
├── infrastructure.yaml # Network & shared services accounts
└── workloads.yaml      # Application workload accounts
```

### Supported Account Types
Based on AWS Security Reference Architecture (SRA):

- **`management`** - Organization management account (required)
- **`log_archive`** - Centralized logging account (required)  
- **`audit`** - Security audit account (required)
- **`network`** - Network hub and connectivity
- **`workload`** - Application and workload accounts
- **`sandbox`** - Development and experimentation
- **`shared_services`** - Shared infrastructure services

## Adding New Accounts

### Prerequisites (CRITICAL)
**AWS accounts must be created via CLI FIRST** - the module only manages existing accounts.

### Step 1: Create the AWS Account

```bash
# For GovCloud (most common)
aws organizations create-gov-cloud-account \
  --account-name "MyApp-Production" \
  --email "myapp-prod@yourorg.com" \
  --profile your-management-profile

# For Commercial AWS
aws organizations create-account \
  --account-name "MyApp-Production" \
  --email "myapp-prod@yourorg.com" \
  --profile your-management-profile
```

**Important**: Note the returned Account ID - you'll need it for the YAML configuration.

### Step 2: Add to YAML Configuration

Choose the appropriate YAML file based on account type:

#### For Workload Accounts (`config/accounts/workloads.yaml`)

**Complete Example - Customer Portal Production Account:**

```bash
# Step 1: Create account via CLI first
aws organizations create-gov-cloud-account \
  --account-name "CustomerPortal-Production" \
  --email "customer-portal-prod@yourorg.com" \
  --profile cnscca-gov-mgmt
# Note the returned Account ID
```

```yaml
# Step 2: Add to config/accounts/workloads.yaml
customer_portal_production:
  account_id: "ACCOUNT_ID_FROM_CLI"  # From CLI above
  account_name: "CustomerPortal-Production"  # Must match CLI exactly
  email: "customer-portal-prod@yourorg.com"  # Must match CLI exactly
  account_type: workload
  ou: Workloads_Prod  # Workloads_Prod or Workloads_NonProd
  lifecycle: prod     # Must match OU lifecycle
  additional_tags:
    Owner: "Customer Experience Team"
    Purpose: "Customer Portal Application"
```

```bash
# Step 3: Deploy
tofu validate  # Check configuration
tofu plan      # Review changes
tofu apply     # Deploy if plan looks good
```

**Result**: Account imported, placed in correct OU, SSO access configured automatically.

#### For Infrastructure Accounts (`config/accounts/infrastructure.yaml`)
```yaml
# Add new entry with unique key
shared_services_prod:
  account_id: "ACCOUNT_ID_FROM_CLI"
  account_name: "SharedServices-Production"
  email: "shared-services-prod@yourorg.com"
  account_type: shared_services
  ou: Infrastructure_Prod
  lifecycle: prod
  additional_tags:
    Owner: "Platform Team"
    Purpose: "Shared Infrastructure Services"
```

### Step 3: Choose the Right Organizational Unit (OU)

Available OUs (defined in `config/organizational-units/`):

**Production OUs** (`lifecycle: prod`):
- `Security` - For audit, log_archive accounts
- `Infrastructure_Prod` - For production network/shared services
- `Workloads_Prod` - For production applications

**Non-Production OUs** (`lifecycle: nonprod`):
- `Infrastructure_NonProd` - For test/dev network/shared services  
- `Workloads_NonProd` - For test/dev applications
- `Sandbox` - For experimentation
- `Policy_Staging` - For policy testing

### Step 4: Validate and Apply

```bash
# Validate configuration
tofu validate

# Check what will be created (should show account import and OU assignment)
tofu plan

# Apply changes
tofu apply
```

## Configuration Guidelines

### Account Naming Conventions
- **Account Names**: `{Purpose}-{Environment}` (e.g., "MyApp-Production")
- **Email Addresses**: Unique per account, recommend `{purpose}-{env}@yourorg.com`
- **YAML Keys**: Use underscore format (e.g., `myapp_production`)

### Required Fields
All accounts must include:
- `account_id` - 12-digit AWS account ID
- `account_name` - Must match CLI creation exactly
- `email` - Must match CLI creation exactly  
- `account_type` - Must be valid SRA account type
- `ou` - Must match existing OU name
- `lifecycle` - Either `prod` or `nonprod`

### Optional Fields
- `additional_tags` - Custom tags for the account
- `create_govcloud` - Set to `true` if creating GovCloud paired account

## Account Lifecycle Management

### Moving Accounts Between OUs
Simply change the `ou` field in the YAML file:
```yaml
my_account:
  # ... other fields
  ou: Workloads_Prod  # Changed from Workloads_NonProd
```

### Updating Account Tags
Modify the `additional_tags` section:
```yaml
my_account:
  # ... other fields  
  additional_tags:
    Owner: "New Team"
    Purpose: "Updated Purpose"
    CostCenter: "CC-1234"
```

### Removing Accounts
1. Remove the account entry from the YAML file
2. Run `tofu plan` to see the planned removal
3. **WARNING**: This will remove the account from the organization
4. Consider moving to `Suspended` OU instead of removal

## Troubleshooting

### Common Errors

#### "Account ID format validation failed"
- Ensure account ID is exactly 12 digits
- Remove any spaces or formatting

#### "Email format validation failed"  
- Use proper email format: `name@domain.com`
- Ensure email is unique across all accounts

#### "Invalid account_type"
- Use only SRA-compliant account types (see list above)
- Check spelling and case sensitivity

#### "OU not found"
- Ensure OU exists in `config/organizational-units/`
- Check exact spelling and case

#### "Account name changes not permitted in GovCloud"
- GovCloud accounts cannot change names after creation
- Ensure YAML name matches existing account name exactly

### Validation
The yaml-transform module includes built-in validation:
- Account ID format (12 digits)
- Email format validation
- Lifecycle values (`prod`/`nonprod` only)
- Account type validation against SRA types
- OU existence validation

Enable validation with `enable_validation = true` in the yaml-transform module configuration.

## Best Practices

1. **Plan Before Apply**: Always run `tofu plan` before `tofu apply`
2. **One Account at a Time**: Add accounts incrementally for easier troubleshooting
3. **Consistent Naming**: Use organization-wide naming conventions
4. **Email Management**: Maintain a spreadsheet of account emails
5. **Version Control**: Commit YAML changes with descriptive messages
6. **Documentation**: Update this guide as your organization's practices evolve

## Advanced Usage

### Bulk Account Creation
For multiple accounts, create them all via CLI first, then add all YAML entries at once:

```bash
# Create multiple accounts
for app in app1 app2 app3; do
  aws organizations create-gov-cloud-account \
    --account-name "${app}-production" \
    --email "${app}-prod@yourorg.com"
done
```

### Integration with CI/CD
The YAML approach works well with CI/CD pipelines:
1. Developers submit PRs with new account YAML entries
2. CI validates YAML format and required fields
3. PR review ensures proper account placement and tags
4. Merge triggers automated deployment

This approach provides audit trails and prevents unauthorized account creation.

## Migration from Variable-Based Configuration

If you're migrating from the older `terraform.tfvars` variable-based approach to YAML configuration, follow these steps:

### Migration Benefits

1. **Cleaner Configuration**: Separate files for different account types
2. **Better Version Control**: YAML shows cleaner diffs than HCL variables
3. **Built-in Validation**: Comprehensive validation of account data
4. **Enhanced Integration**: Better data structures for security services modules
5. **No Infrastructure Impact**: Same resource keys, no destruction

### Migration Steps

#### Step 1: Backup Current Configuration
```bash
cd examples/
cp terraform.tfvars terraform.tfvars.backup
```

#### Step 2: Switch to YAML Configuration
The module includes a pre-configured YAML setup:
```bash
# Use the YAML-enabled terraform.tfvars
cp terraform.tfvars.yaml-version terraform.tfvars
```

#### Step 3: Validate Migration
```bash
# Re-initialize to use yaml-transform module
tofu init

# Validate configuration
tofu validate

# Plan to verify no infrastructure changes
tofu plan
```

**Expected Result**: `tofu plan` should show "No changes" since the same account IDs are used as resource keys.

#### Step 4: Configuration Comparison

**Before (Variable-based)**:
```hcl
# terraform.tfvars
aws_account_parameters = {
  "ACCOUNT_ID_FROM_CLI" = {
    name = "SCCA Root"
    email = "nmmes-scca-test-org-root@stigian.com"
    ou = "Root"
    lifecycle = "prod"
    account_type = "management"
  }
}
```

**After (YAML-based)**:
```yaml
# config/accounts/foundation.yaml
management_account:
  account_id: "ACCOUNT_ID_FROM_CLI"
  account_name: "SCCA Root"
  email: "nmmes-scca-test-org-root@stigian.com"
  account_type: management
  ou: Root
  lifecycle: prod
```

### Rollback Plan
If issues arise, you can always revert:
```bash
cp terraform.tfvars.backup terraform.tfvars
tofu init  # Re-initialize
```
