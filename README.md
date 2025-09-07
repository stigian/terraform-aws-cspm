# CNSCCA-CSPM

**DoD Zero Trust CSPM** - Modular OpenTofu implementation of **DISA Secure Cloud Computing Architecture (SCCA)** with cross-account security services for AWS multi-account environments.

**Key Features:**
- **DISA SCCA Compliance**: Virtual Data Center Security Stack (VDSS) implementation
- **Modular Architecture**: Specialized modules for flexible security deployment
- **Cross-Account Security**: Centralized monitoring from audit account across all accounts
- **YAML Configuration**: Simplified account and OU management through declarative config
- **AWS SRA Alignment**: Security Reference Architecture patterns with SCCA enhancements

## Modular Security Architecture

This implementation provides **8 specialized modules** that work together to create a comprehensive DISA SCCA-compliant security posture:

### **Foundation Modules (Required)**

| Module | Status | Purpose | Key Features |
|--------|--------|---------|--------------|
| **organizations** | ✅ Complete | Multi-account structure, OU management | AWS SRA OUs, account placement, Control Tower integration |
| **sso** | ✅ Complete | Centralized identity & access control | Permission sets, account assignments, external IdP support |
| **controltower** | ✅ Complete | Governance & compliance baseline | Landing zone, guardrails, security baseline |

### **Security Services (Cross-Account)**

| Module | Status | Purpose | DISA SCCA Alignment |
|--------|--------|---------|-------------------|
| **guardduty** | ✅ Production | Threat detection & monitoring | VDSS requirement 2.1.2.6 |
| **detective** | ✅ Production | Security investigation & analysis | Enhanced incident response |
| **securityhub** | ✅ Production | Centralized security findings | VDSS monitoring consolidation |
| **awsconfig** | ✅ Production | Configuration compliance & drift | VDSS compliance monitoring |
| **inspector2** | � Planned | Vulnerability assessment | Continuous security assessment |

### **Architecture Pattern: Audit Account as Security Hub**

All security services use the **audit account as delegated administrator**, providing:

```
┌─── Cross-Account Security Services ────────────────────┐
│                                                        │
│ Audit Account (Delegated Administrator)               │
│ ├── GuardDuty Organization Admin                       │
│ ├── Detective Behavior Graph                           │
│ ├── Security Hub Central Configuration                 │
│ ├── Config Organization Admin                          │
│ └── [Future] Inspector2 Organization Admin             │
│                                                        │
│         ▼ Automatic Enrollment ▼                       │
│                                                        │
│ All Organization Member Accounts                       │
│ ├── Auto-enabled security services                     │
│ ├── Findings forwarded to audit account                │
│ └── Centralized compliance monitoring                  │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Configuration Strategy

### YAML-Based Account Management

Accounts and organizational units are managed through **declarative YAML configuration** files in `examples/config/`:

```
examples/config/
├── accounts/
│   ├── foundation.yaml    # Management account
│   ├── security.yaml      # Log archive, audit accounts
│   ├── infrastructure.yaml # Network, shared services
│   └── workloads.yaml     # Application accounts
├── organizational-units/
│   └── custom-ous.yaml    # Additional OUs beyond AWS SRA
└── sso/
    └── groups.yaml        # SSO groups and assignments
```

**Example Account Definition:**
```yaml
# examples/config/accounts/security.yaml
audit_account:
  account_id: "123456789012"
  account_name: "YourOrg-Security-Audit"
  email: "aws-audit@yourorg.com"
  account_type: audit
  ou: Security
  lifecycle: prod
  additional_tags:
    Owner: "Security Team"
    Purpose: "Security Audit & Compliance"
```

### Module Integration Pattern

The `examples/main.tf` demonstrates the integration pattern:

```hcl
# Foundation
module "organizations" { ... }
module "controltower" { ... }
module "sso" { ... }

# Security Services (depend on foundation)
module "guardduty" { ... }
module "detective" { ... }
module "securityhub" { ... }
module "awsconfig" { ... }
```
- Be consistent across your organization

## Quick Start

### Prerequisites
- **AWS CLI**: Account creation via Organizations CLI (accounts must exist before Terraform management)
- **OpenTofu 1.6+**: This is an OpenTofu project (not Terraform)
- **AWS Profiles**: Management account access with OrganizationFullAccess
- **Account IDs**: Collect account IDs from CLI creation for configuration

### Step 1: Create AWS Accounts (Required First)

```bash
# GovCloud (most common for DoD environments)
aws organizations create-gov-cloud-account
  --account-name "YourOrg-Security-Audit"
  --email "aws-audit@yourorg.com"
  --profile your-management-profile

# Commercial AWS
aws organizations create-account
  --account-name "YourOrg-Workloads-App1"
  --email "aws-app1@yourorg.com"
  --profile your-management-profile
```

### Step 2: Configure Accounts in YAML

```bash
# Copy example configuration
cp -r examples/config /path/to/your/deployment/

# Edit account files with your actual account IDs and details
vim config/accounts/security.yaml
vim config/accounts/workloads.yaml
```

### Step 3: Deploy Foundation Services

```bash
cd /path/to/your/deployment
tofu plan
tofu apply

# Foundation modules deploy first:
# 1. Organizations (account placement, OUs)
# 2. Control Tower (landing zone, guardrails)
# 3. SSO (identity and access management)
```

### Step 4: Enable Security Services

Security services automatically deploy after foundation completion:
- **GuardDuty**: Organization-wide threat detection
- **Detective**: Security investigation capabilities
- **Security Hub**: Centralized security findings
- **Config**: Configuration compliance monitoring

## Documentation Structure

**Role-Based Documentation** in `/docs/by_persona/`:

| Role | Documentation | Purpose |
|------|---------------|---------|
| **Administrator** | [administrator.md](docs/by_persona/administrator.md) | Setup, deployment, configuration management |
| **Operations** | [operations.md](docs/by_persona/operations.md) | Daily operations, account management, monitoring |
| **Security Team** | [security-team.md](docs/by_persona/security-team.md) | Security architecture, incident response, compliance |

## Current Implementation Status

### ✅ **Production Ready (Fully Implemented)**

- **organizations**: Complete multi-account structure with AWS SRA OUs
- **controltower**: Landing zone with guardrails and security baseline
- **sso**: Role-based access control with external IdP integration
- **guardduty**: Organization-wide threat detection with all protection plans
- **detective**: Security investigation graphs with 30-day retention
- **securityhub**: Centralized security findings with configuration policies
- **awsconfig**: Configuration compliance monitoring across all accounts

### 🚧 **Planned Enhancements**

- **inspector2**: Vulnerability assessment and container scanning
- **logging**: Centralized logging module (currently handled by Control Tower)
- Enhanced security automation and response capabilities

## Module Dependencies and Deployment Order

The modules have clear dependencies that ensure proper deployment sequencing:

```
Foundation Layer:
├── organizations (account placement, OU structure)
├── controltower (governance baseline, depends on organizations)
└── sso (identity management, depends on organizations)

Security Services Layer:
├── guardduty (depends on controltower)
├── detective (depends on guardduty)
├── securityhub (depends on guardduty)
└── awsconfig (depends on controltower)
```

All security services automatically:
- Use audit account as delegated administrator
- Enable organization-wide with auto-enrollment
- Forward findings to centralized audit account
- Follow DISA SCCA and AWS SRA best practices


## IAM Identity Center

AWS Control Tower configures IAM Identity Center to provide a centralized view of identity and access management (IAM) activity across all accounts in the AWS Organization. IAM Identity Center provides a single location to view and manage IAM activity, including changes to IAM policies, roles, and users.


# Prerequisites

## Required Permissions

The identity deploying this Infrastructure as Code (IaC) requires **full administrative permissions** in the AWS Organization management account, including:

- `OrganizationsFullAccess` or equivalent permissions to manage AWS Organizations
- `SSOFullAccess` or equivalent permissions to manage IAM Identity Center
- Administrative permissions for all CSPM services (GuardDuty, Security Hub, etc.)
- Permission to create and manage IAM roles and policies

## AWS Account Requirements

### Account Creation

**All AWS accounts must be created in advance** before deploying this module. The module manages existing accounts only and does not create new accounts.

#### For AWS Commercial Regions:
- Create accounts through the AWS Organizations console, CLI, or API
- Accounts automatically join the organization when created

#### For AWS GovCloud Regions:
AWS GovCloud accounts must be created using specific procedures. Reference the official AWS documentation:

- **[Creating AWS GovCloud Accounts](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/getting-started-sign-up.html)**
- **[Creating GovCloud Accounts via Organizations](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/getting-started-sign-up-org.html)**

> [!IMPORTANT]
> **GovCloud Account Names**: In AWS GovCloud, account names can only be changed from the paired commercial account. When running this module in GovCloud, account name changes are automatically ignored to prevent deployment failures.

### Required AWS Control Tower Account Types

Following AWS Control Tower and Security Reference Architecture requirements, these three accounts are mandatory:

| Account Type | AccountType Tag | OU Placement | Purpose | Required |
|--------------|-----------------|--------------|---------|----------|
| **Management** | `"management"` | Root | Organization root, billing, governance | ✅ Yes |
| **Log Archive** | `"log_archive"` | Security | Centralized logging and long-term storage | ✅ Yes |
| **Audit** | `"audit"` | Security | Security audit, compliance monitoring | ✅ Yes |
| **Network** | `"network"` | Infrastructure_Prod | Central network connectivity (Transit Gateway) | ⚠️ Recommended |

**Control Tower Requirements:**
- Management account MUST be in Root OU with `AccountType = "management"`
- Log Archive account MUST be in Security OU with `AccountType = "log_archive"`
- Audit account MUST be in Security OU with `AccountType = "audit"`
- Only one of each required account type is allowed
- All three accounts must exist before deploying Control Tower landing zone

### Additional Account Types (Optional)

| Account Type | Purpose | OU Placement |
|--------------|---------|--------------|
| **Shared Services** | Shared infrastructure (DNS, monitoring) | Infrastructure_Prod |
| **Security Tooling** | Security tools, SIEM, threat detection | Security |
| **Workload Production** | Production applications | Workloads_Prod |
| **Workload Non-Production** | Development, testing environments | Workloads_Test |
| **Sandbox** | Experimental, proof-of-concept | Sandbox |

## AWS Organizations Configuration

### Organization Setup
1. **Enable All Features**: The organization must have "All Features" enabled (not just billing features)
2. **Service Access Principals**: The module automatically configures required service access principals
3. **Account Membership**: All accounts must be members of the organization before SSO assignments can be created

### Organizational Units (OUs)
The module automatically creates AWS SRA-compliant OUs:
- `Security` - Security and compliance accounts
- `Infrastructure_Prod` - Production infrastructure
- `Infrastructure_Test` - Non-production infrastructure
- `Workloads_Prod` - Production workloads
- `Workloads_Test` - Development/testing workloads
- `Sandbox` - Experimental accounts
- `Policy_Staging` - Policy testing
- `Suspended` - Decommissioned accounts

## Module Architecture

This solution uses a modular architecture with two main components:

### Organizations Module (`modules/organizations`)
- Manages AWS Organizations and Organizational Units
- Handles existing account organization membership
- Provides automatic GovCloud detection and handling
- Outputs account mappings for other modules

### SSO Module (`modules/sso`)
- Manages IAM Identity Center (formerly AWS SSO)
- Creates persona-based permission sets and groups
- Handles account assignments based on AWS SRA patterns
- Optional Microsoft Entra ID (Azure AD) integration

## Deployment Requirements

### OpenTofu/Terraform Versions
- **OpenTofu**: >= 1.6
- **Terraform**: >= 1.6 (if using Terraform instead of OpenTofu)

### AWS Provider
- **hashicorp/aws**: >= 5.0.0

### Azure AD Provider (Optional)
- **hashicorp/azuread**: ~> 3.0.0 (only if enabling Entra ID integration)

## Quick Start

1. **Create AWS accounts** using appropriate method for your partition
2. **Configure AWS credentials** for the management account
3. **Clone this repository**
4. **Copy example configuration**: `cp examples/terraform.tfvars.example terraform.tfvars`
5. **Update variables** with your actual account IDs and email addresses
6. **Deploy**: `tofu init && tofu plan && tofu apply`

For detailed examples, see:
- [Organizations Module Examples](./modules/organizations/examples/)
- [SSO Module Examples](./modules/sso/examples/)

# Pre-deployment steps

# Account Setup

> [!IMPORTANT]
> **Updated Guidance**: This module now uses a modular architecture with separate organizations and SSO modules. Account creation requirements have been updated to reflect AWS SRA best practices.

## AWS GovCloud Account Creation

## Getting Started

For detailed setup and operational guidance, see the **role-based documentation**:

### 📋 [Administrator Guide](docs/by_persona/administrator.md)
**Setup, deployment, and configuration management**
- Prerequisites and account creation workflow
- Initial deployment procedures
- Configuration management patterns
- Provider setup and authentication

### 🔧 [Operations Guide](docs/by_persona/operations.md)
**Daily operations and maintenance**
- Account management procedures
- Adding accounts and OUs
- Security monitoring workflows
- Emergency procedures and troubleshooting

### 🛡️ [Security Team Guide](docs/by_persona/security-team.md)
**Security architecture and incident response**
- Security service overview and status
- Incident response procedures
- Compliance monitoring and reporting
- Security service configuration

## Module References

| Module | Purpose | README | Status |
|--------|---------|--------|--------|
| **organizations** | Multi-account structure, AWS SRA OUs | [📖](modules/organizations/README.md) | ✅ Complete |
| **controltower** | Governance baseline, guardrails | [📖](modules/controltower/README.md) | ✅ Complete |
| **sso** | Identity & access management | [📖](modules/sso/README.md) | ✅ Complete |
| **guardduty** | Threat detection | [📖](modules/guardduty/README.md) | ✅ Complete |
| **detective** | Security investigation | [📖](modules/detective/README.md) | ✅ Complete |
| **securityhub** | Centralized security findings | [📖](modules/securityhub/README.md) | ✅ Complete |
| **awsconfig** | Configuration compliance | [📖](modules/awsconfig/README.md) | ✅ Complete |
| **inspector2** | Vulnerability assessment | [📖](modules/inspector2/README.md) | 🚧 Planned |

## Support and Troubleshooting

### Quick Troubleshooting
- **Account creation**: Accounts must be created via AWS Organizations CLI first
- **GovCloud limitations**: Account names cannot be changed in GovCloud partition
- **Control Tower conflicts**: SSO module auto-detects Control Tower management
- **Import failures**: Check resource naming patterns for your AWS partition

### Documentation Structure
```
docs/
├── by_persona/           # Role-based operational guides
│   ├── administrator.md  # Setup and deployment
│   ├── operations.md     # Daily operations
│   └── security-team.md  # Security architecture
└── architecture/         # Technical architecture (may be outdated)
```

### Example Deployment
See `examples/` directory for complete working configuration including:
- YAML-based account configuration
- Module integration patterns
- Provider setup for multi-account access
- Real-world variable examples

---

*This project implements DISA SCCA requirements with AWS Security Reference Architecture patterns, providing a complete foundation for DoD Zero Trust cloud environments.*

## Organization Membership Verification

Before deployment, verify all accounts are organization members:

```bash
# List organization accounts
aws organizations list-accounts --query 'Accounts[].{Id:Id,Name:Name,Email:Email,Status:Status}'

# Verify specific account membership
aws organizations describe-account --account-id "123456789012"
```

## Required IAM Permissions

The deployment identity needs these permission policies (or equivalent custom policies):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "organizations:*",
        "sso:*",
        "sso-admin:*",
        "identitystore:*",
        "guardduty:*",
        "detective:*",
        "inspector2:*",
        "securityhub:*",
        "config:*",
        "cloudtrail:*",
        "iam:*"
      ],
      "Resource": "*"
    }
  ]
}
```


# Post-deployment steps

## Organizations Module

After successful deployment:

1. **Verify Organization Structure**: Check that OUs were created according to AWS SRA patterns
2. **Confirm Account Placement**: Ensure accounts are in their designated OUs
3. **Review Partition Detection**: Verify the module correctly detected your AWS partition (commercial/GovCloud)

```bash
# Check organization structure
aws organizations list-organizational-units-for-parent --parent-id r-xxxx

# Verify account OU assignments
aws organizations list-accounts-for-parent --parent-id ou-xxxx
```

## SSO Module

### Permission Set Verification

1. Login to the management account
2. Navigate to **IAM Identity Center** → **Permission sets**
3. Verify persona-based permission sets were created:
   - `aws-admin` (AdministratorAccess)
   - `aws-cyber-sec-eng` (PowerUserAccess + planned custom policies)
   - `aws-net-admin` (NetworkAdministrator)
   - `aws-power-user` (PowerUserAccess)
   - `aws-sec-auditor` (SecurityAudit)
   - `aws-sys-admin` (SystemAdministrator)

### Group Assignment Verification

1. Navigate to **IAM Identity Center** → **Groups**
2. Verify groups were created and assigned to appropriate accounts based on SRA patterns
3. Check account assignments match your `account_role_mapping` configuration

### User Management

> [!NOTE]
> This module creates groups and permission sets but does not create users. You must:

1. **Add users to groups** manually through IAM Identity Center console
2. **Configure external identity provider** if using Entra ID integration
3. **Set up MFA requirements** per your organization's security policies



## GuardDuty

> [!NOTE]
> Member account enablement is now retroactive. Existing accounts are automatically enrolled, but it may take up to 24 hours for all accounts to appear as enabled in the GuardDuty console.

1. Login to the audit account
1. Navigate to _Accounts_ in the left hand pane
1. Verify every account _Status_ column shows _Enabled_
1. If some accounts are not yet enabled, wait up to 24 hours for GuardDuty to complete retroactive enrollment.



## Detective

> [!NOTE]
> New member accounts are automatically enrolled in Detective. Only accounts that existed before Detective org auto-enrollment was enabled require manual enrollment (click the _Enable all accounts_ button in the console).

1. Login to the audit account
1. Navigate to _Settings_ -> _Account management_ in the left hand pane
1. Verify member accounts _Status_ column shows _Enabled_
1. If not, simply click the _Enable all accounts_ button


## Inspector

No action required.


## Control Tower

AWS Control Tower will not automatically enroll non-Landing Zone accounts, you must do this from the management account Control Tower service page in the Organization tab.

If in the future you need to enroll/onboard new accounts to Control Tower, see these references:

- [Enroll an existing AWS account | AWS Docs](https://docs.aws.amazon.com/controltower/latest/userguide/enroll-account.html)
- [Field Notes: Enroll Existing AWS Accounts into AWS Control Tower | AWS Blogs](https://aws.amazon.com/blogs/architecture/field-notes-enroll-existing-aws-accounts-into-aws-control-tower/) for more information.
- [Enabling AWS Configuration on Control Tower Main Account](https://repost.aws/questions/QUF9Umvk9aTkyL78HJJ-vYRg/enabling-aws-configuration-on-control-tower-main-account)


## Security Hub

No action required.

Insight categories for Critical and High findings are automatically configured. Depending on your specific security posture you may wish to [fine tune the Security Standard controls](https://aws.github.io/aws-security-services-best-practices/guides/security-hub/#fine-tuning-security-standard-controls) to reduce noise.


## Config

No action required.


## CloudTrail

No action required.


## IAM Identity Center

### Initial Configuration
This module configures IAM Identity Center with persona-based access control following AWS SRA patterns. The basic setup is automated, but additional customization may be required.

### User Assignment
**Manual Action Required**: After deployment, assign users to the appropriate groups:

1. Navigate to **IAM Identity Center** → **Groups**
2. Select a group (e.g., `aws-admin`, `aws-power-user`)
3. Click **Add users** and assign appropriate personnel
4. Repeat for all groups based on your access control requirements

### External Identity Provider Integration
For organizations using Microsoft Entra ID (formerly Azure AD):

1. **Enable Entra Integration**: Set `enable_entra_integration = true` in the SSO module
2. **Configure Variables**: Provide required Entra ID tenant information
3. **Complete SAML Setup**: Follow the [Microsoft documentation](https://learn.microsoft.com/en-us/entra/identity/saas-apps/aws-single-sign-on-tutorial) for SAML configuration

### Control Tower Compatibility
The module automatically detects AWS Control Tower and adjusts behavior accordingly:
- If Control Tower is managing Identity Center, SSO management is disabled
- Entra ID integration can still be enabled for external identity federation
- Manual override possible with `enable_sso_management = false`

Control Tower applies a basic configuration for IAM Identity Center in the management account. We choose **not** to delegate administration of IAM Identity Center to another account, instead leaving it in the management account for security reasons.

---

## Module Usage Examples

### Basic Organizations-Only Deployment

```hcl
# Configure AWS provider for management account
provider "aws" {
  region = "us-gov-west-1" # or us-east-1 for commercial
  # Ensure your credentials target the management account
}

module "organizations" {
  source = "./modules/organizations"

  project = "my-organization"
  aws_account_parameters = {
    "123456789012" = {
      email     = "management@example.com"
      lifecycle = "prod"
      name      = "Management Account"
      ou        = "Root"
      tags      = { AccountType = "management" }
    }
    "234567890123" = {
      email     = "log-archive@example.com"
      lifecycle = "prod"
      name      = "Log Archive"
      ou        = "Security"
      tags      = { AccountType = "log_archive" }
    }
  }

  global_tags = {
    Project = "my-organization"
    Owner   = "platform-team"
  }
}
```

### Full Deployment with SSO Integration

```hcl
# Configure AWS provider for management account
provider "aws" {
  region = "us-gov-west-1" # or us-east-1 for commercial
  # Ensure your credentials target the management account
}

module "organizations" {
  source = "./modules/organizations"
  # ... organizations configuration
}

module "sso" {
  source = "./modules/sso"

  project        = "my-organization"
  account_id_map = module.organizations.account_id_map

  account_role_mapping = {
    "Management Account" = "management"
    "Log Archive"        = "log_archive"
    "Security Audit"     = "audit"
    "Network Hub"        = "network"
  }

  enable_sso_management = true
  global_tags = {
    Project = "my-organization"
    Owner   = "platform-team"
  }
}
```

---

## Troubleshooting

### Common Issues

#### GovCloud Account Name Changes
**Error**: `Account name changes are not permitted in GovCloud`
**Solution**: The module automatically detects GovCloud and ignores name changes. Ensure your configuration matches current account names in the AWS Console.

#### Import Failures
**Error**: `Configuration for import target does not exist`
**Solution**: This can occur after module updates. Check that import blocks reference the correct resource names:
- Commercial AWS: `module.organizations.aws_organizations_account.commercial[account_id]`
- GovCloud: `module.organizations.aws_organizations_account.govcloud[account_id]`

#### SSO Assignment Failures
**Error**: `Account not found in organization`
**Solution**: Ensure all accounts referenced in `account_role_mapping` are members of the AWS Organization before creating SSO assignments.

#### Control Tower Conflicts
**Error**: `Identity Center is managed by Control Tower`
**Solution**: Set `enable_sso_management = false` or `auto_detect_control_tower = true` to automatically handle Control Tower environments.

### Getting Help

1. **Check Examples**: Review the [examples](./examples/) directory for working configurations
2. **Module Documentation**: See individual module READMEs for detailed parameter information
3. **AWS Documentation**: Reference official AWS documentation for service-specific guidance
4. **Terraform/OpenTofu Validation**: Run `tofu validate` to check configuration syntax

### Debug Information

The modules provide debug outputs for troubleshooting:

```hcl
# Check AWS partition detection
output "aws_partition" {
  value = module.organizations.aws_partition
}

# Verify GovCloud detection
output "is_govcloud" {
  value = module.organizations.is_govcloud
}

# Review account structure
output "account_structure" {
  value = module.organizations.organizational_unit_ids
}
```

---

## 📚 Documentation

### Quick References
- **[Complete Documentation Index](./docs/README.md)** - 📚 Central hub organized by role (Admin/Ops/Security)
- **[Operations Guide](./docs/operations-guide.md)** - 🔧 Daily tasks and maintenance procedures
- **[Extending OUs and Lifecycles](./docs/extending-ous-and-lifecycles.md)** - ⭐ Essential guide for customization
- **[Control Tower Troubleshooting](./docs/control-tower-troubleshooting.md)** - ⚠️ Essential for re-deployments
- **[Integration Strategy](./docs/integration-strategy.md)** - Architectural patterns and decisions
- **[Multi-Account Provider Patterns](./docs/MULTI_ACCOUNT_PROVIDER_PATTERNS.md)** - Advanced provider management

### Module Documentation
- **[Organizations Module](./modules/organizations/README.md)** - Core AWS Organizations management
- **[SSO Module](./modules/sso/README.md)** - IAM Identity Center integration
- **[Control Tower Module](./modules/controltower/README.md)** - Control Tower deployment

### Configuration References
- **[Account Schema](./config/account-schema.yaml)** - Account parameter definitions
- **[SRA Account Types](./config/sra-account-types.yaml)** - Valid account type values
- **[Examples](./examples/)** - Real-world configuration examples

### Need Help?
- **Daily operations?** → [Operations Guide](./docs/operations-guide.md)
- **Adding new OUs?** → [Extending OUs and Lifecycles](./docs/extending-ous-and-lifecycles.md)
- **Account management questions?** → [Operations Guide](./docs/operations-guide.md)
- **SSO configuration?** → [SSO Module README](./modules/sso/README.md)
- **Control Tower deployment issues?** → [Control Tower Troubleshooting](./docs/control-tower-troubleshooting.md)
- **Architecture questions?** → [Integration Strategy](./docs/integration-strategy.md)

---

## Recent Improvements

### v2.0 - Modular Architecture & GovCloud Support

**Key Features:**
- **Modular Design**: Split into separate organizations and SSO modules for flexibility
- **GovCloud Support**: Automatic detection and handling of AWS GovCloud partition limitations
- **AWS SRA Compliance**: Full alignment with AWS Security Reference Architecture patterns
- **Enhanced Documentation**: Comprehensive examples and troubleshooting guides

**Technical Improvements:**
- Automatic AWS partition detection (`aws`, `aws-us-gov`)
- Conditional resource creation based on partition
- GovCloud account name change protection (automatic `ignore_changes`)
- Unified outputs that abstract partition-specific implementations
- Safe resource migration with `moved` blocks

**New Documentation:**
- Detailed prerequisites and account creation procedures
- GovCloud-specific guidance with AWS CLI examples
- Troubleshooting section with common issues and solutions
- Module usage examples for different deployment scenarios

**Breaking Changes:**
- Resource names changed from `aws_organizations_account.this` to partition-specific names
- Module structure reorganized (use `moved` blocks for safe migration)
- Variable structure updated to follow AWS SRA taxonomy

For detailed migration guidance, see the individual module READMEs and examples directories.
