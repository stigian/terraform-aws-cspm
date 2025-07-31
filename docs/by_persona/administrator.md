# Administration Overview

**Administrator's Guide** - Setup, deployment, and configuration management for terraform-aws-cspm.

## Quick Start for New Administrators

### Prerequisites Checklist
- [ ] AWS Management account access with OrganizationFullAccess
- [ ] OpenTofu 1.6+ installed (not Terraform)
- [ ] AWS CLI configured with appropriate profiles
- [ ] Understanding of AWS Organizations and Control Tower concepts

### Essential First Steps
1. **[Account Creation Workflow](#account-creation-workflow)** - Create accounts via CLI first
2. **[Initial Deployment](#initial-deployment)** - Deploy foundation services
3. **[Configuration Management](#configuration-management)** - Understand configuration patterns
4. **[Access Setup](#access-management)** - Configure administrative access

## Account Creation Workflow

### Critical Principle: CLI-First Account Creation
**AWS accounts MUST be created via CLI before Terraform management.**

#### GovCloud Account Creation (Most Common)
```bash
# Create management account (if needed)
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Management" \
  --email "aws-mgmt@yourorg.com" \
  --profile your-management-profile

# Create security accounts  
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Security-Audit" \
  --email "aws-audit@yourorg.com" \
  --profile your-management-profile

aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Security-LogArchive" \
  --email "aws-logs@yourorg.com" \
  --profile your-management-profile
```

#### Commercial AWS Account Creation
```bash
aws organizations create-account \
  --account-name "YourOrg-Workloads-App1" \
  --email "aws-app1@yourorg.com" \
  --profile your-management-profile
```

#### Configuration Alignment
**Critical**: Use EXACT names and emails from CLI in Terraform configuration:
```hcl
aws_account_parameters = {
  "261523644253" = {
    name         = "YourOrg-Security-Audit"      # MUST match CLI exactly
    email        = "aws-audit@yourorg.com"      # MUST match CLI exactly
    ou           = "Security"                    # OU placement
    lifecycle    = "prod"                       # prod/nonprod
    account_type = "audit"                      # AWS SRA account type
  }
}
```

## Initial Deployment

### Deployment Sequence (Required Order)

#### 1. Organizations Foundation
```bash
cd examples/
tofu init
tofu plan -target=module.organizations
tofu apply -target=module.organizations
```

#### 2. SSO Configuration
```bash
tofu plan -target=module.sso
tofu apply -target=module.sso
```

#### 3. Control Tower Landing Zone
```bash
tofu plan -target=module.controltower
tofu apply -target=module.controltower
```

#### 4. Security Services (After Control Tower)
```bash
# Deploy GuardDuty first
tofu plan -target=module.guardduty
tofu apply -target=module.guardduty

# Future: Security Hub, Config, etc.
# tofu apply -target=module.securityhub
```

### Verification Checklist
- [ ] All accounts in correct OUs (Organizations console)
- [ ] Control Tower Landing Zone active (Control Tower console)
- [ ] SSO working with appropriate access (SSO console)
- [ ] GuardDuty enabled organization-wide (audit account)
- [ ] No Terraform plan changes after deployment

## Configuration Management

### Core Configuration Files

#### Primary Configuration: `examples/terraform.tfvars`
```hcl
# Account definitions - MUST match CLI-created accounts
aws_account_parameters = {
  "123456789012" = {
    name         = "Exact-CLI-Name"
    email        = "exact-cli-email@domain.com"
    ou           = "Workloads_Prod"
    lifecycle    = "prod"
    account_type = "workload"
  }
}

# OU structure - easily extensible
organizational_units = {
  Infrastructure_Prod    = { lifecycle = "prod" }
  Infrastructure_NonProd = { lifecycle = "nonprod" }
  Workloads_Prod        = { lifecycle = "prod" }
  Workloads_NonProd     = { lifecycle = "nonprod" }
  # Add custom OUs here - no code changes needed
}

# SSO configuration
sso_groups = {
  SecurityTeam = {
    description = "Security team access"
    permission_sets = ["SecurityTeamRole"]
  }
}

permission_sets = {
  SecurityTeamRole = {
    description      = "Security team access"
    managed_policies = ["ViewOnlyAccess", "SecurityAudit"]
    accounts = {
      audit       = ["SecurityTeam"]
      log_archive = ["SecurityTeam"] 
    }
  }
}
```

#### YAML-Based Configuration (Advanced)
For complex configurations, use YAML approach:
```bash
cd examples/advanced-yaml-config/
# Edit config/accounts.yaml and config/sso.yaml
tofu apply
```

### Configuration Validation

#### Built-in Validation Rules
The module includes 5 essential validations:

1. **Lifecycle Consistency**: Account lifecycle must match OU lifecycle
2. **OU Existence**: Account OU must exist in organizational_units
3. **Valid Lifecycles**: Only 'prod' and 'nonprod' allowed
4. **Account Types**: Must use valid AWS SRA account types
5. **Unique Emails**: All account emails must be unique

#### Testing Configuration
```bash
# Run unit tests (organizations module)
cd modules/organizations && tofu test

# Validate full configuration
cd examples/
tofu validate
tofu plan  # Review all changes before applying
```

## Architecture Understanding

### Hybrid Control Tower + Organizations Design

#### Why Hybrid Architecture?
- **Control Tower**: Manages Security/Sandbox OUs with built-in guardrails
- **Organizations**: Manages Infrastructure/Workloads OUs with flexibility
- **Best of Both**: Security baseline + organizational customization

#### Service Boundaries
```
┌─── Control Tower Domain ───────────────────────────────┐
│ • Security OU (audit, log_archive accounts)           │
│ • Sandbox OU (development/testing)                    │
│ • Built-in guardrails and compliance                  │
│ • Account Factory integration                         │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─── Organizations Domain ───────────────────────────────┐
│ • Infrastructure OUs (network, shared services)       │
│ • Workloads OUs (applications, business units)        │
│ • Custom OU structures                                │
│ • Flexible account management                         │
└────────────────────────────────────────────────────────┘
```

#### Integration Layer: yaml-transform Module
Coordinates between Control Tower and Organizations:
```hcl
# Excludes Control Tower accounts from Organizations management
organizations_account_parameters = var.control_tower_enabled ? {
  for k, v in local.all_accounts : k => v 
  if !contains(local.control_tower_account_ids, k)
} : local.all_accounts
```

## Access Management

### Administrator Access Patterns

#### Management Account Access
- **Purpose**: Organizational resource management
- **Scope**: Organizations, Control Tower, top-level services
- **Access Method**: Direct AWS credentials or SSO

#### Audit Account Access  
- **Purpose**: Security service management and monitoring
- **Scope**: GuardDuty, Security Hub, Config, Detective
- **Access Method**: Cross-account role or SSO

#### SSO Administrative Access
```hcl
permission_sets = {
  AdminRole = {
    description      = "Full administrative access"
    managed_policies = ["AdministratorAccess"]
    accounts = {
      management  = ["AdminTeam"]
      audit       = ["AdminTeam", "SecurityTeam"]
      log_archive = ["AdminTeam", "AuditTeam"]
    }
  }
}
```

### Security Considerations
- **Least Privilege**: Grant minimum necessary permissions
- **Separation of Duties**: Different roles for different functions
- **Regular Reviews**: Monthly access audits and updates
- **MFA Enforcement**: Multi-factor authentication required

## Provider Configuration

### External Provider Pattern
Security services use external providers for proper dependency management:

```hcl
# In examples/main.tf
provider "aws" {
  alias   = "audit"
  profile = "cnscca-audit"  # or appropriate profile
}

provider "aws" {
  alias   = "log_archive"
  profile = "cnscca-logs"
}

# Pass to modules
module "guardduty" {
  source = "../modules/guardduty"
  
  providers = {
    aws.audit = aws.audit
  }
  
  depends_on = [module.controltower]
}
```

### Profile Management
```bash
# ~/.aws/config example
[profile cnscca-gov-mgmt]
region = us-gov-west-1
output = json

[profile cnscca-audit]
region = us-gov-west-1
role_arn = arn:aws-us-gov:iam::261523644253:role/OrganizationAccountAccessRole
source_profile = cnscca-gov-mgmt

[profile cnscca-logs]
region = us-gov-west-1
role_arn = arn:aws-us-gov:iam::261503748007:role/OrganizationAccountAccessRole
source_profile = cnscca-gov-mgmt
```

## Customization and Extension

### Adding New OUs
Simply extend the `organizational_units` variable:
```hcl
organizational_units = {
  # Standard OUs
  Infrastructure_Prod    = { lifecycle = "prod" }
  Infrastructure_NonProd = { lifecycle = "nonprod" }
  Workloads_Prod        = { lifecycle = "prod" }
  Workloads_NonProd     = { lifecycle = "nonprod" }
  
  # Custom additions - no code changes needed!
  Research_Prod         = { lifecycle = "prod" }
  Development           = { lifecycle = "nonprod" }
  Sandbox_Test          = { lifecycle = "nonprod" }
}
```

### Custom Account Types
Extend SRA account types in `config/sra-account-types.yaml`:
```yaml
# Custom account types for organization-specific needs
custom_types:
  - research
  - training
  - demonstration
```

### Advanced Configurations
See detailed guides:
- **[Extending OUs and Lifecycles](./extending-ous-and-lifecycles.md)**
- **[Integration Strategy](./integration-strategy.md)**
- **[Multi-Account Provider Patterns](./MULTI_ACCOUNT_PROVIDER_PATTERNS.md)**

## Deployment Strategies

### Environment Progression
```
┌─── Development ────────────────────────────────────────┐
│ • Test configurations in non-prod accounts            │
│ • Validate new features and changes                   │
│ • Limited blast radius                                │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─── Staging ────────────────────────────────────────────┐
│ • Full production-like testing                        │
│ • Integration testing with security services          │
│ • Final validation before production                  │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─── Production ─────────────────────────────────────────┐
│ • Controlled deployment windows                       │
│ • Staged rollout of changes                           │
│ • Comprehensive monitoring and rollback capability    │
└────────────────────────────────────────────────────────┘
```

### Change Management Process
1. **Planning**: Document changes and impact assessment
2. **Testing**: Validate in development/staging environments
3. **Approval**: Security and operations team review
4. **Deployment**: Staged deployment with monitoring
5. **Verification**: Confirm expected outcomes
6. **Documentation**: Update procedures and runbooks

## Monitoring and Maintenance

### Infrastructure Health Monitoring

#### Daily Checks
- **Service Status**: All modules deployed and healthy
- **Account Status**: All accounts in correct OUs
- **Security Posture**: GuardDuty findings review

#### Weekly Reviews
- **Configuration Drift**: Terraform plan shows no changes
- **Security Compliance**: Control Tower compliance dashboard
- **Access Patterns**: SSO usage and permission effectiveness

#### Monthly Maintenance
- **Module Updates**: Review and update module versions
- **Documentation**: Keep documentation current
- **Security Review**: Access audits and permission cleanup

### Backup and Recovery

#### Configuration Backup
```bash
# Backup Terraform state
aws s3 sync . s3://backup-bucket/terraform-state/$(date +%Y%m%d)/

# Export current configuration
tofu show -json > current-state-$(date +%Y%m%d).json

# Backup Organizations structure
aws organizations describe-organization > org-structure-$(date +%Y%m%d).json
```

#### Recovery Procedures
1. **Assess Scope**: Determine what needs recovery
2. **Restore State**: Use backed-up Terraform state
3. **Verify Configuration**: Ensure configuration matches desired state
4. **Redeploy Services**: Apply Terraform to restore services
5. **Validate**: Confirm all services operational

## Troubleshooting

### Common Administrator Issues

| Issue | Symptoms | Solution | Prevention |
|-------|----------|----------|------------|
| **Account creation errors** | CLI failures | Check permissions and quotas | Regular quota monitoring |
| **Provider authentication** | Access denied | Verify profiles and roles | Credential rotation process |
| **Validation failures** | Terraform errors | Check configuration consistency | Use validation checklist |
| **Control Tower issues** | Guardrail failures | Review troubleshooting guide | Regular compliance checks |

### Diagnostic Tools
```bash
# Check Terraform configuration
tofu validate
tofu plan -detailed-exitcode

# Verify AWS access
aws sts get-caller-identity --profile cnscca-gov-mgmt
aws organizations describe-organization

# Test cross-account access
aws sts assume-role --role-arn CROSS_ACCOUNT_ROLE --role-session-name test

# Check service status
aws guardduty list-detectors --region us-gov-west-1
aws controltower get-landing-zone --region us-east-1
```

## Advanced Topics

### State Management
- **Remote State**: Use S3 backend with DynamoDB locking
- **State Isolation**: Separate states for different environments
- **State Security**: Encrypt state files and restrict access

### CI/CD Integration
- **Automated Testing**: Unit tests for configuration changes
- **Deployment Pipelines**: Automated deployment with approvals
- **Rollback Capability**: Automated rollback on failures

### Multi-Region Considerations
- **Primary Region**: Deploy core services in primary region
- **Secondary Regions**: Disaster recovery and compliance requirements
- **Cross-Region**: Coordinate security services across regions

---

**📋 Detailed Service Configuration**: [Service Documentation](./by_service/)
**📋 Operations Procedures**: [Operations Overview](./operations-overview.md)

*Last updated: July 31, 2025*
