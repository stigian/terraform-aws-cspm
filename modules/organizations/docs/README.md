# Organizations Service Documentation

**AWS Organizations** - Account management and organizational unit structure.

## Overview

Organizations provides centralized management of multiple AWS accounts with hierarchical organization, policy management, and consolidated billing.

### Implementation Status
- ✅ **Module**: `/modules/organizations/`
- ✅ **Deployment**: Production ready with 5 passing unit tests
- ✅ **Hybrid Architecture**: Manages Infrastructure/Workloads OUs
- ✅ **SRA Compliance**: AWS best practices implementation

### Key Features
- **Account Management**: Centralized AWS account lifecycle
- **OU Structure**: Hierarchical organizational units
- **Policy Management**: Service control policies (SCPs)
- **Consolidated Billing**: Centralized cost management
- **Account Tagging**: Standardized account metadata

## Architecture

```
┌─── AWS Organization Root ──────────────────────────────┐
│                                                        │
│ ┌─── Control Tower Managed ─────────────────────────┐  │
│ │ • Security OU                                    │  │
│ │ • Sandbox OU                                     │  │
│ └──────────────────────────────────────────────────┘  │
│                                                        │
│ ┌─── Organizations Module Managed ──────────────────┐  │
│ │                                                  │  │
│ │ ┌─── Infrastructure OUs ─────────────────────┐   │  │
│ │ │ • Infrastructure_Prod                     │   │  │
│ │ │ • Infrastructure_NonProd                  │   │  │
│ │ └───────────────────────────────────────────┘   │  │
│ │                                                  │  │
│ │ ┌─── Workloads OUs ──────────────────────────┐   │  │
│ │ │ • Workloads_Prod                          │   │  │
│ │ │ • Workloads_NonProd                       │   │  │
│ │ │ • Workloads_Test                          │   │  │
│ │ └───────────────────────────────────────────┘   │  │
│ │                                                  │  │
│ └──────────────────────────────────────────────────┘  │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[Module README](../../modules/organizations/README.md)** | Technical implementation and configuration | Developers |
| **[Account Management Guide](../../account-management-guide.md)** | Account creation workflows | Administrators |
| **[Extending OUs Guide](../../extending-ous-and-lifecycles.md)** | Customization and extension | Administrators |

## Configuration

### Account Definition Pattern
```hcl
aws_account_parameters = {
  "123456789012" = {
    name         = "ACME-Infrastructure-Network"    # Must match CLI creation
    email        = "aws-network@acme.com"          # Must match CLI creation  
    ou           = "Infrastructure_Prod"           # OU placement
    lifecycle    = "prod"                          # prod/nonprod validation
    account_type = "network"                       # SRA account type
  }
  "123456789013" = {
    name         = "ACME-Workloads-App1"
    email        = "aws-app1@acme.com"
    ou           = "Workloads_Prod" 
    lifecycle    = "prod"
    account_type = "workload"
  }
}
```

### OU Structure Definition
```hcl
organizational_units = {
  # Standard AWS SRA OUs
  Infrastructure_Prod    = { lifecycle = "prod" }
  Infrastructure_NonProd = { lifecycle = "nonprod" }
  Workloads_Prod        = { lifecycle = "prod" }
  Workloads_NonProd     = { lifecycle = "nonprod" }
  
  # Custom extensions
  Workloads_Test        = { lifecycle = "nonprod" }
  Development           = { lifecycle = "nonprod" }
}
```

### Key Variables
- `aws_account_parameters`: Account definitions with OU placement
- `organizational_units`: OU structure and lifecycle mappings
- `enable_policy_types`: Enable service control policies
- `account_defaults`: Default tags and settings

## Operations

### Account Management Workflow

#### 1. Create Account via CLI (Required First Step)
```bash
# GovCloud example
aws organizations create-gov-cloud-account \
  --account-name "ACME-Infrastructure-Network" \
  --email "aws-network@acme.com" \
  --profile your-management-profile

# Commercial AWS example  
aws organizations create-account \
  --account-name "ACME-Workloads-App1" \
  --email "aws-app1@acme.com" \
  --profile your-management-profile
```

#### 2. Add to Terraform Configuration
```hcl
# Add to aws_account_parameters
"NEW_ACCOUNT_ID" = {
  name         = "Exact-CLI-Name"           # Must match CLI exactly
  email        = "exact-email@domain.com"  # Must match CLI exactly
  ou           = "Workloads_Prod"          # Desired OU placement
  lifecycle    = "prod"                    # prod/nonprod
  account_type = "workload"                # SRA account type
}
```

#### 3. Deploy Changes
```bash
tofu plan   # Review changes
tofu apply  # Apply account placement
```

### OU Management

#### Adding New OUs
Simply extend the `organizational_units` variable:
```hcl
organizational_units = {
  # Existing OUs...
  NewDepartment_Prod = { lifecycle = "prod" }
  NewDepartment_Test = { lifecycle = "nonprod" }
}
```

#### OU Lifecycle Validation
- **prod lifecycle**: Production accounts with strict controls
- **nonprod lifecycle**: Development/test accounts with relaxed policies
- **Validation**: Module enforces lifecycle consistency

### Account Import Strategy
For existing AWS accounts:
```hcl
import {
  to = module.organizations.aws_organizations_account.govcloud["123456"]
  id = "123456"
}
```

## Validation Rules

The module includes 5 essential validation rules:

### 1. Lifecycle Consistency
```hcl
# Accounts must match OU lifecycle
validation {
  condition = can([
    for account_id, config in var.aws_account_parameters :
    config if lookup(var.organizational_units, config.ou, {}).lifecycle == config.lifecycle
  ])
  error_message = "Account lifecycle must match OU lifecycle"
}
```

### 2. OU Existence
```hcl
validation {
  condition = alltrue([
    for account_id, config in var.aws_account_parameters :
    contains(keys(var.organizational_units), config.ou)
  ])
  error_message = "Account OU must exist in organizational_units"
}
```

### 3. Valid Lifecycles
```hcl
validation {
  condition = alltrue([
    for account_id, config in var.aws_account_parameters :
    contains(["prod", "nonprod"], config.lifecycle)
  ])
  error_message = "Lifecycle must be 'prod' or 'nonprod'"
}
```

### 4. Account Type Validation
```hcl
validation {
  condition = alltrue([
    for account_id, config in var.aws_account_parameters :
    contains(local.valid_account_types, config.account_type)
  ])
  error_message = "Invalid account_type. Must be valid AWS SRA account type"
}
```

### 5. Unique Email Addresses
```hcl
validation {
  condition = length(values(var.aws_account_parameters)[*].email) == 
              length(distinct(values(var.aws_account_parameters)[*].email))
  error_message = "Account email addresses must be unique"
}
```

## Testing

### Unit Test Suite
Located in `/modules/organizations/tests/`:

```bash
# Run all tests
cd modules/organizations && tofu test

# Individual test files
tofu test tests/valid_account_configuration.tftest.hcl
tofu test tests/invalid_lifecycle_mismatch.tftest.hcl
tofu test tests/invalid_ou_reference.tftest.hcl
tofu test tests/invalid_lifecycle_value.tftest.hcl  
tofu test tests/duplicate_email_addresses.tftest.hcl
```

### Test Coverage
- ✅ **Valid configurations**: Proper account and OU setup
- ✅ **Lifecycle validation**: Prevents mismatched lifecycles
- ✅ **OU validation**: Ensures valid OU references
- ✅ **Email uniqueness**: Prevents duplicate emails
- ✅ **Account type validation**: Enforces SRA account types

## Hybrid Architecture Integration

### yaml-transform Integration
The `yaml-transform` module coordinates between Control Tower and Organizations:

```hcl
# Excludes Control Tower accounts from Organizations management
organizations_account_parameters = var.control_tower_enabled ? {
  for k, v in local.all_accounts : k => v 
  if !contains(local.control_tower_account_ids, k)
} : local.all_accounts
```

### Benefits of Hybrid Approach
- **Separation of Concerns**: Clear boundaries between services
- **Best of Both Worlds**: Control Tower security + Organizations flexibility
- **Reduced Complexity**: Each module manages appropriate resources
- **Cost Optimization**: No duplicate management overhead

## AWS SRA Compliance

### Account Structure
- ✅ **Lifecycle-based OUs**: Infrastructure vs Workloads separation
- ✅ **Environment Separation**: Prod vs NonProd isolation
- ✅ **Account Types**: Follows AWS SRA account type taxonomy
- ✅ **Tagging Strategy**: Consistent metadata across accounts

### Security Integration
- **SSO Integration**: Account type drives permission set assignments
- **Security Services**: Provides account inventory for cross-account security
- **Compliance**: Supports Control Tower guardrails and Config rules
- **Audit Trail**: Complete account lifecycle tracking

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| **Validation failures** | Account/OU mismatch | Check lifecycle consistency |
| **Import errors** | Existing account conflicts | Use proper import blocks |
| **Provider auth errors** | Missing management account access | Verify AWS credentials |
| **OU creation failures** | Duplicate OU names | Check existing organization structure |

### Diagnostic Commands
```bash
# Check organization structure
aws organizations list-organizational-units-for-parent --parent-id ROOT_ID

# List accounts
aws organizations list-accounts

# Check account OU placement
aws organizations list-parents --child-id ACCOUNT_ID
```

## Future Enhancements

### Advanced Features
- 🚧 **Service Control Policies**: Preventive governance controls
- 🚧 **Account Factory Integration**: Streamlined provisioning
- 🚧 **Cost Management**: Advanced billing and cost allocation
- 🚧 **Multi-Region Support**: Regional service deployments

### Integration Improvements
- 🚧 **Config Integration**: Automated compliance monitoring
- 🚧 **CloudTrail Organization**: Enhanced audit logging
- 🚧 **Backup Policies**: Organization-wide backup strategies

---

*Last updated: July 31, 2025*
