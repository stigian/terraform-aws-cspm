# SSO Module

AWS IAM Identity Center implementation for centralized authentication and authorization across multi-account environments. Provides role-based access control with automatic account assignments based on account types.

## Overview

AWS IAM Identity Center provides centralized authentication and authorization for AWS accounts with support for external identity providers and role-based access control. The module implements foundational identity management optimized for multi-account environments and DoD security requirements.

## Architecture Pattern

```
┌─── AWS IAM Identity Center ────────────────────────────┐
│                                                        │
│ ┌─── Permission Sets ───────────────────────────────┐  │
│ │ • aws_admin          (AdministratorAccess)       │  │
│ │ • aws_cyber_sec_eng  (PowerUserAccess*)          │  │
│ │ • aws_net_admin      (NetworkAdministrator)      │  │
│ │ • aws_power_user     (PowerUserAccess)           │  │
│ │ • aws_sec_auditor    (SecurityAudit)             │  │
│ │ • aws_sys_admin      (SystemAdministrator)       │  │
│ └────────────────────────────────────────────────────┘  │
│                     │                                  │
│                     ▼                                  │
│ ┌─── Account Type Assignments ──────────────────────┐  │
│ │ Management → aws_admin                            │  │
│ │ Log Archive → aws_admin, aws_cyber_sec_eng,       │  │
│ │               aws_sec_auditor                     │  │
│ │ Audit → aws_admin, aws_cyber_sec_eng,             │  │
│ │         aws_sec_auditor                           │  │
│ │ Network → aws_admin, aws_cyber_sec_eng,           │  │
│ │           aws_net_admin, aws_power_user,          │  │
│ │           aws_sec_auditor, aws_sys_admin          │  │
│ │ Workload → aws_power_user, aws_cyber_sec_eng,     │  │
│ │            aws_sec_auditor, aws_sys_admin         │  │
│ └────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘

* Placeholder for future DoD-specific policy development
```

The module automatically assigns permission sets to accounts based on their `account_role_mapping`, implementing a security-first approach where management and audit accounts receive elevated access while workload accounts follow least-privilege principles.

## Deployment Requirements

### Prerequisites

1. **AWS IAM Identity Center Instance**
   ```bash
   # Check if Identity Center is already enabled in region
   aws sso-admin list-instances --profile your-management-profile
   ```

2. **Organizations Module Foundation**
   - Organizations module must be deployed first to provide account mappings
   - Account types defined in `account_role_mapping` for automatic group assignment

3. **Provider Configuration**
   ```hcl
   # Management account provider for SSO resources
   provider "aws" {
     alias   = "management"
     profile = "your-management-profile"
     region  = var.aws_region
   }
   ```

### Basic Configuration

```hcl
module "sso" {
  source = "./modules/sso"
  
  # Required: Project name for resource naming
  project = "my-project"
  
  # Required: Account ID mappings from Organizations module
  account_id_map = module.organizations.account_id_map
  
  # Required: Global tags for all resources
  global_tags = {
    Project     = "my-project"
    Environment = "production"
    ManagedBy   = "opentofu"
  }
  
  # Optional: Account type mappings for automatic group assignments
  account_role_mapping = {
    "Management-Account"     = "management"
    "Security-Log-Archive"  = "log_archive"
    "Security-Audit"        = "audit"
    "Network-Hub"           = "network"
    "Workload-Production"   = "workload"
  }
  
  # Required: Initial admin user configuration (Day 1 protection)
  # Option 1: Use existing SSO user ID
  existing_admin_user_id = "1234567890-abcd-efgh-ijkl-123456789012"
  
  # Option 2: Create new admin users
  initial_admin_users = [
    {
      user_name    = "admin.user"
      display_name = "Admin User"
      email        = "admin@yourorg.com"
      given_name   = "Admin"
      family_name  = "User"
      admin_level  = "full"  # "full" or "security"
    }
  ]
  
  # Optional: Enable/disable SSO management (auto-detects Control Tower)
  enable_sso_management = true
  auto_detect_control_tower = true
  
  # Optional: Microsoft Entra ID integration
  enable_entra_integration = false
}
```

### Account Type Integration

The module uses automatic assignment logic based on account types defined in `locals.tf`:

```hcl
# Account type to group mappings (from locals.tf)
account_groups = {
  # Core Foundation Accounts (Required by AWS SRA)
  management = [
    "aws_admin", # Management account requires full admin access for organization control
  ]
  log_archive = [
    "aws_admin",         # Log management requires admin access
    "aws_cyber_sec_eng", # Security engineers need access to logs
    "aws_sec_auditor",   # Auditors need read access to logs
  ]
  audit = [
    "aws_admin",         # Audit account management
    "aws_cyber_sec_eng", # Security engineering oversight
    "aws_sec_auditor",   # Primary auditing capabilities
  ]
  
  # Network & Infrastructure Accounts
  network = [
    "aws_admin",         # Network admins need full access for infrastructure
    "aws_cyber_sec_eng", # Security engineering for network controls
    "aws_net_admin",     # Network administration for VPCs, TGW, etc.
    "aws_power_user",    # General operations
    "aws_sec_auditor",   # Security auditing capabilities
    "aws_sys_admin",     # System administration for infrastructure
  ]
  
  # Workload Accounts (all types)
  workload = [
    "aws_power_user",    # Workload management capabilities
    "aws_cyber_sec_eng", # Security oversight for all workloads
    "aws_sec_auditor",   # Security monitoring and auditing
    "aws_sys_admin",     # System administration
  ]
}
```

## Troubleshooting

### Common Issues

**Identity Center Not Available**
```
Error: Failed to create Identity Store group
│ Error: operation error SSO Admin: CreateGroup, https response error StatusCode: 400
```

*Solution*: Enable IAM Identity Center in the management account region first:
```bash
aws sso-admin create-instance --profile your-management-profile
```

**Account Assignment Failures**
```
Error: Account assignment failed for account ACCOUNT_ID
```

*Solutions*:
1. Verify account exists in organization: `aws organizations list-accounts`
2. Check account role mapping is correct in `account_role_mapping` variable
3. Confirm Identity Center instance exists in correct region

**Permission Set Policy Errors**
```
Error: Invalid managed policy ARN
```

*Solution*: Verify policy ARNs match correct partition (aws-us-gov for GovCloud):
```bash
# Check available managed policies
aws iam list-policies --scope AWS --query 'Policies[?contains(PolicyName, `Security`)].Arn'
```

**Day 1 Lockout Prevention**
```
Error: Either existing_admin_user_id must be provided OR initial_admin_users must contain at least one user
```

*Solution*: Provide either an existing SSO user ID or create new admin users:
```hcl
# Option 1: Use existing user
existing_admin_user_id = "1234567890-abcd-efgh-ijkl-123456789012"

# Option 2: Create new users
initial_admin_users = [
  {
    user_name    = "admin"
    display_name = "Administrator"
    email        = "admin@yourorg.com"
    given_name   = "Admin"
    family_name  = "User"
    admin_level  = "full"
  }
]
```

### Validation Commands

**Verify Identity Center Configuration**
```bash
# List all permission sets
aws sso-admin list-permission-sets \
  --instance-arn $(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text) \
  --profile your-management-profile

# Check account assignments for specific account
aws sso-admin list-account-assignments \
  --instance-arn $(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text) \
  --account-id YOUR_ACCOUNT_ID \
  --profile your-management-profile
```

**Verify Group Memberships**
```bash
# List all groups
aws identitystore list-groups \
  --identity-store-id $(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text) \
  --profile your-management-profile

# List users in specific group
aws identitystore list-group-memberships \
  --identity-store-id $(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text) \
  --group-id GROUP_ID \
  --profile your-management-profile
```

## Integration with Other Modules

### Organizations Module Dependencies
- **Required**: `account_id_map` output for account-to-group assignments
- **Required**: Account role mapping for automatic permission assignment
- **Recommended**: Deploy Organizations module before SSO module

### Control Tower Integration
- **Auto-Detection**: Module automatically detects Control Tower presence
- **SSO Management**: Can manage SSO even with Control Tower (when using self-managed SSO)
- **Account Requirements**: Control Tower requires specific account types (management, log_archive, audit)

### Security Services Integration
- **Identity-based Policies**: SSO permission sets apply to security service access
- **Cross-account Access**: SSO enables centralized access to distributed security services
- **Audit Trail**: All SSO access logged through CloudTrail in management account

## DoD-Specific Considerations

### GovCloud Deployment
The module automatically detects AWS partition and uses correct managed policy ARNs:
```hcl
# Automatic partition detection
managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
```

### Security Requirements
- **Multi-Factor Authentication**: Enforced through IAM Identity Center configuration
- **Session Management**: 8-hour default sessions (PT8H) for all permission sets
- **Access Logging**: All authentication events logged to CloudTrail
- **Day 1 Protection**: Prevents lockout by requiring admin user configuration

### Compliance Considerations
- **Least Privilege**: Permission sets implement minimum required access based on account type
- **Role-Based Access**: Account type mappings enforce organizational access patterns
- **Audit Trail**: Complete access history available through CloudTrail and Identity Center logs
- **Separation of Duties**: Different permission sets for operational vs security functions