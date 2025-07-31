# SSO Service Documentation

**AWS IAM Identity Center (SSO)** - Centralized identity and access management.

## Overview

IAM Identity Center provides centralized authentication and authorization for AWS accounts with integration to external identity providers and fine-grained permission management.

### Implementation Status
- ✅ **Module**: `/modules/sso/`
- ✅ **Deployment**: Production ready
- ✅ **Integration**: Works with Organizations for account-based access
- ✅ **Account Type Mapping**: Automatic group assignments based on account types

### Key Features
- **Single Sign-On**: Centralized access to multiple AWS accounts
- **Permission Sets**: Role-based access control with managed policies
- **Group Management**: Organize users by function and responsibility
- **Account Assignments**: Automatic access provisioning based on account types
- **External Identity**: Integration with corporate identity providers

## Architecture

```
┌─── IAM Identity Center ────────────────────────────────┐
│                                                        │
│ ┌─── User Groups ───────────────────────────────────┐  │
│ │ • SecurityTeam    │ • AdminTeam                  │  │
│ │ • AuditTeam       │ • DeveloperTeam              │  │
│ │ • NetworkTeam     │ • OperationsTeam             │  │
│ └────────────────────────────────────────────────────┘  │
│                     │                                  │
│                     ▼                                  │
│ ┌─── Permission Sets ───────────────────────────────┐  │
│ │ • SecurityAuditorRole                            │  │
│ │ • AdminRole                                      │  │
│ │ • ReadOnlyRole                                   │  │
│ │ • DeveloperRole                                  │  │
│ └────────────────────────────────────────────────────┘  │
│                     │                                  │
│                     ▼                                  │
│ ┌─── Account Assignments ───────────────────────────┐  │
│ │ Audit Account     → SecurityTeam, AuditTeam      │  │
│ │ Management Account → AdminTeam                   │  │
│ │ Workload Accounts → DeveloperTeam                │  │
│ │ Network Accounts  → NetworkTeam                  │  │
│ └────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

## Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[Module README](../../modules/sso/README.md)** | Technical implementation details | Developers |
| **[Operations Overview](../../operations-overview.md#access-management)** | Daily SSO management procedures | Operations teams |

## Configuration

### Basic SSO Setup
```hcl
# Groups organized by function
sso_groups = {
  SecurityTeam = {
    description = "Security and compliance team"
    permission_sets = ["SecurityAuditorRole", "ReadOnlyRole"]
  }
  AdminTeam = {
    description = "System administrators"  
    permission_sets = ["AdminRole"]
  }
  DeveloperTeam = {
    description = "Application developers"
    permission_sets = ["DeveloperRole"]
  }
}

# Permission sets with managed policies
permission_sets = {
  SecurityAuditorRole = {
    description      = "Security auditing and monitoring"
    managed_policies = ["SecurityAudit", "ViewOnlyAccess"]
    accounts = {
      audit       = ["SecurityTeam"]
      log_archive = ["SecurityTeam"]
      management  = ["SecurityTeam"]
    }
  }
  
  AdminRole = {
    description      = "Full administrative access"
    managed_policies = ["AdministratorAccess"]
    accounts = {
      management = ["AdminTeam"]
      audit      = ["AdminTeam"]
    }
  }
  
  DeveloperRole = {
    description      = "Development access"
    managed_policies = ["PowerUserAccess"]
    accounts = {
      workload = ["DeveloperTeam"]
    }
  }
}
```

### Account Type Integration
The SSO module automatically assigns groups based on account types:

```hcl
# Automatic group assignment logic
locals {
  account_type_groups = {
    management  = ["AdminTeam"]
    audit       = ["SecurityTeam", "AuditTeam"]
    log_archive = ["SecurityTeam", "AuditTeam"]
    network     = ["NetworkTeam", "AdminTeam"]
    workload    = ["DeveloperTeam"]
  }
}
```

## Operations

### User Management

#### Adding New Users
1. **Identity Center Console**: Add user to appropriate groups
2. **Group Assignment**: Users inherit permission sets from groups
3. **Account Access**: Access automatically provisioned based on group membership
4. **Verification**: Confirm user can access assigned accounts

#### Managing Groups
```hcl
# Add new group
sso_groups = {
  # Existing groups...
  NewTeam = {
    description = "New team description"
    permission_sets = ["SpecificRole"]
  }
}
```

#### Permission Set Management
- **Managed Policies**: Use AWS managed policies when possible
- **Custom Policies**: Create inline policies for specific needs
- **Least Privilege**: Grant minimum necessary permissions
- **Regular Review**: Audit permission sets quarterly

### Account Access Patterns

#### By Account Type
| Account Type | Default Groups | Access Level | Purpose |
|-------------|----------------|--------------|---------|
| **management** | AdminTeam | Full admin | Organizational management |
| **audit** | SecurityTeam, AuditTeam | Security audit | Security services and monitoring |
| **log_archive** | SecurityTeam, AuditTeam | Log access | Centralized logging and compliance |
| **network** | NetworkTeam, AdminTeam | Network admin | Network infrastructure |
| **workload** | DeveloperTeam | Development | Application workloads |

#### Cross-Account Access
```bash
# Using AWS CLI with SSO
aws sso login --profile sso-profile

# List available accounts
aws sso list-accounts --access-token TOKEN

# Assume role in specific account
aws sts assume-role \
  --role-arn "arn:aws:iam::ACCOUNT:role/AWSReservedSSO_RoleName_*" \
  --role-session-name "session-name"
```

### Integration with Organizations

#### Account Discovery
- **Automatic Detection**: SSO discovers accounts from Organizations module
- **Account Type Mapping**: Uses account_type tags for group assignments
- **Dynamic Updates**: New accounts automatically get appropriate access

#### OU-Based Access (Planned)
Future enhancement to provide OU-level access patterns:
```hcl
# Planned: OU-based access
ou_access_patterns = {
  "Security" = {
    groups = ["SecurityTeam", "AuditTeam"]
    permission_sets = ["SecurityAuditorRole"]
  }
  "Workloads_Prod" = {
    groups = ["DeveloperTeam"]
    permission_sets = ["DeveloperRole"]
  }
}
```

## Security Considerations

### Access Control Principles
- **Least Privilege**: Users get minimum necessary access
- **Separation of Duties**: Different roles for different functions
- **Regular Reviews**: Quarterly access audits and cleanup
- **MFA Enforcement**: Multi-factor authentication required

### Permission Set Design
- **Managed Policies**: Prefer AWS managed policies
- **Custom Policies**: Document and justify custom permissions
- **Resource Restrictions**: Limit access to specific resources when possible
- **Time-Limited Access**: Consider temporary elevated access patterns

### Audit and Compliance
- **Access Logging**: CloudTrail captures all SSO activity
- **Permission Reviews**: Regular review of permission sets and assignments
- **User Activity**: Monitor user access patterns and usage
- **Compliance Reporting**: Generate access reports for audits

## Troubleshooting

### Common Issues

| Issue | Symptoms | Solution | Prevention |
|-------|----------|----------|------------|
| **User cannot access account** | Access denied errors | Check group membership and permission sets | Verify account assignments |
| **Permission denied** | Specific action failures | Review permission set policies | Use least privilege principle |
| **SSO login failures** | Authentication errors | Check Identity Center configuration | Monitor service health |
| **Missing accounts** | Account not in SSO portal | Verify account discovery from Organizations | Check account type tags |

### Diagnostic Commands
```bash
# Check SSO configuration
aws sso-admin list-instances

# List permission sets
aws sso-admin list-permission-sets --instance-arn INSTANCE_ARN

# Check account assignments
aws sso-admin list-account-assignments --instance-arn INSTANCE_ARN --account-id ACCOUNT_ID

# Verify user access
aws sts get-caller-identity --profile sso-profile

# List account assignments for specific permission set
aws sso-admin list-account-assignments \
  --instance-arn $(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text) \
  --account-id "123456789012" \
  --permission-set-arn "permission-set-arn"
```

### Emergency SSO Recovery

#### Re-creating Permission Sets
If permission sets become corrupted or misconfigured:

```bash
# 1. Remove from Terraform state
tofu state rm "module.sso.aws_ssoadmin_permission_set.this[\"RoleName\"]"

# 2. Delete the permission set (if needed)
aws sso-admin delete-permission-set \
  --instance-arn INSTANCE_ARN \
  --permission-set-arn PERMISSION_SET_ARN

# 3. Retry deployment
tofu plan -target=module.sso
tofu apply -target=module.sso
```

#### Checking User Assignment Status
```bash
# List all users
aws identitystore list-users --identity-store-id IDENTITY_STORE_ID

# List group memberships for a user
aws identitystore list-group-memberships-for-member \
  --identity-store-id IDENTITY_STORE_ID \
  --member-id UserId=USER_ID

# Check what accounts a user can access through SSO
aws sso list-accounts --access-token ACCESS_TOKEN
```

## Integration Points

### Organizations Module
- **Account Discovery**: Automatically discovers accounts for SSO assignment
- **Account Types**: Uses account_type for automatic group assignments
- **OU Structure**: Planned integration with OU-based access patterns

### Security Services
- **Audit Account**: Security teams get access to security service consoles
- **Cross-Account Roles**: SSO roles work with security service delegation
- **Monitoring**: Security team access to GuardDuty, Security Hub, etc.

### Control Tower
- **Service Catalog**: Integration with Account Factory (planned)
- **Guardrails**: SSO access subject to Control Tower guardrails
- **Baseline Configuration**: SSO baseline applied to new accounts

## Future Enhancements

### Phase 1: Enhanced Access Patterns
- 🚧 **OU-Based Access**: Automatic access based on OU membership
- 🚧 **Conditional Access**: Time and location-based access controls
- 🚧 **Just-In-Time Access**: Temporary elevated permissions

### Phase 2: External Integration
- 🚧 **SAML Identity Provider**: Corporate identity provider integration
- 🚧 **SCIM Provisioning**: Automated user and group provisioning
- 🚧 **Multi-Factor Authentication**: Enhanced MFA options

### Phase 3: Advanced Features
- 🚧 **Risk-Based Access**: Adaptive access based on risk assessment
- 🚧 **Privileged Access**: Enhanced controls for administrative access
- 🚧 **Access Analytics**: Advanced reporting and user behavior analysis

---

*Last updated: July 31, 2025*
