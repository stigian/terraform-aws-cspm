# CNSCCA-CSPM

This OpenTofu module configures Cloud Security Posture Management (CSPM) aligned with **DISA Secure Cloud Computing Architecture (SCCA)** requirements for DoD Zero Trust environments. The design implements AWS Control Tower Landing Zone baseline version 3.3 as the foundation, with additional modular components for Organizations management and IAM Identity Center (SSO) integration.

**Key Features:**
- **DISA SCCA Compliance**: Implements Virtual Data Center Security Stack (VDSS) requirements
- **Simple User Experience**: Clear separation between configuration and module implementation
- **Modular Architecture**: Separate organizations and SSO modules for flexible deployment
- **AWS SRA Fallback**: Follows AWS Security Reference Architecture patterns when SCCA is insufficient
- **GovCloud Support**: Automatic detection and handling of AWS GovCloud partition differences
- **Multi-Partition**: Supports commercial AWS and AWS GovCloud partitions

## DISA SCCA Security Architecture

This module implements a **layered security architecture** that aligns with DISA SCCA component requirements, using Control Tower as the foundational security baseline:

### 🛡️ **Virtual Data Center Security Stack (VDSS) - Core Security**

Control Tower provides the foundational security controls, enhanced with SCCA-compliant security services:

```
Security OU (SCCA VDSS & VDMS Core):
├── Management Account - Organization control, TCCM integration point
├── Log Archive Account - Centralized logging
└── Audit Account - VDSS monitoring, threat detection (GuardDuty, Security Hub, etc.)
```

**SCCA Foundation Provides:**
- ✅ **VDSS Monitoring**: GuardDuty threat detection per SCCA requirement 2.1.2.6
- ✅ **Security Information Capture**: CloudWatch logging per SCCA requirement 2.1.2.11
- ✅ **Centralized Archival**: Log aggregation per SCCA requirement 2.1.2.12
- ✅ **Detective Controls**: Continuous compliance monitoring via Config rules
- ✅ **Security Baseline**: IAM roles, policies, and security foundations

### 🔧 **Tier 2: Your Managed Accounts (Flexible Security)**

For accounts in **your** OUs (Infrastructure, Workloads), you get **complete control** over security services:

```
Your OUs (Organizations Module Managed):
├── Infrastructure OU - Network, shared services accounts
├── Workloads OU - Production and non-production applications
└── Custom OUs - Any additional organizational structure you need
```

**You Can Add:**
- 🔧 **Enhanced Threat Detection**: GuardDuty, Inspector across all accounts
- 🔧 **Custom Compliance**: Additional Config rules beyond Control Tower baseline
- 🔧 **Security Aggregation**: Security Hub for centralized findings
- 🔧 **Workload Security**: Application-specific controls and monitoring

### 🎯 **Perfect Division of Responsibilities**

| Component | Control Tower Handles | You Handle |
|-----------|----------------------|------------|
| **Core Accounts** | Security baseline, audit trail, mandatory compliance | Enhanced monitoring, custom rules |
| **Workload Accounts** | Basic guardrails | Full security stack, application controls |
| **Organizational Structure** | Security & Sandbox OUs | Infrastructure, Workloads, custom OUs |
| **Access Management** | Service roles (when SSO disabled) | User access, permission sets, SAML integration |

### 💪 **Key Benefits**

- **🔒 Unbreakable Foundation**: Critical accounts protected by Control Tower's mandatory controls
- **⚡ Operational Flexibility**: Full control over workload account security configuration
- **📊 Compliance Simplified**: DISA SCCA baseline + enhanced services for specific requirements
- **💰 Cost Optimized**: Pay only for enhanced services where needed, not across all accounts
- **🔍 Centralized Visibility**: All security findings flow to the audit account for unified monitoring

This architecture ensures your **most sensitive accounts** (management, logging, audit) have maximum protection while giving you complete flexibility to tailor security for your **workload accounts** based on specific application needs.

## Quick Start

**PREREQUISITE**: AWS accounts must be created FIRST via AWS Organizations CLI

**Your main job:** Create accounts via CLI, then define them in Terraform. The modules handle all the AWS SRA compliance automatically.

### Step 1: Create AWS Accounts (CLI)

Before using this module, create your AWS accounts using the AWS Organizations CLI:

```bash
# Example: Create Control Tower required accounts with good naming convention
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Management" \
  --email "aws-management@yourorg.com"

aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Security-LogArchive" \
  --email "aws-logs@yourorg.com"

aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Security-Audit" \
  --email "aws-audit@yourorg.com"

# Continue for additional accounts as needed...
```

**Recommended Naming Convention**: `{YourOrg}-{Function}-{Environment}`
- Examples: "ACME-Security-Audit", "ACME-Workload-Prod1"
- Keep names short (AWS has length limits)
- Be consistent across your organization

### Step 2: Configure in Terraform

Configure your AWS credentials for the **management account**, then define your existing accounts using EXACT names and emails from CLI creation:

```hcl
# Configure AWS provider for management account
provider "aws" {
  region = "us-gov-west-1" # or us-east-1 for commercial

  # Option 1: Use AWS_PROFILE (recommended)
  # export AWS_PROFILE=your-management-account-profile

  # Option 2: Assume role (if needed)
  # assume_role {
  #   role_arn = "arn:aws:iam::MGMT-ACCOUNT-ID:role/OrganizationAccountAccessRole"
  # }
}

variable "aws_account_parameters" {
  default = {
    # REQUIRED: Control Tower Management Account
    "123456789012" = {
      name      = "YourOrg-Management"         # EXACT match from CLI
      email     = "aws-mgmt@yourorg.com"       # EXACT match from CLI
      ou        = "Root"                       # REQUIRED: Management in Root
      lifecycle = "prod"
      tags      = { AccountType = "management" } # REQUIRED: Must be "management"
    }
    # REQUIRED: Control Tower Log Archive Account
    "234567890123" = {
      name      = "YourOrg-Security-LogArchive"
      email     = "aws-logs@yourorg.com"
      ou        = "Security"                   # REQUIRED: Log Archive in Security
      lifecycle = "prod"
      tags      = { AccountType = "log_archive" } # REQUIRED: Must be "log_archive"
    }
    # REQUIRED: Control Tower Audit Account
    "345678901234" = {
      name      = "YourOrg-Security-Audit"
      email     = "aws-audit@yourorg.com"
      ou        = "Security"                   # REQUIRED: Audit in Security
      lifecycle = "prod"
      tags      = { AccountType = "audit" }       # REQUIRED: Must be "audit"
    }
  }
}

module "organizations" {
  source = "./modules/organizations"

  aws_account_parameters = var.aws_account_parameters
  project               = "your-organization"
}
```

### Available OUs

The module creates these AWS SRA-compliant OUs automatically:

| OU Name | Purpose | Lifecycle | Typical Accounts |
|---------|---------|-----------|------------------|
| `Root` | Management account only | `prod` | Management account |
| `Security` | Security & compliance | `prod` | Audit, Log Archive |
| `Infrastructure_Prod` | Production infrastructure | `prod` | Network Hub |
| `Infrastructure_Test` | Test infrastructure | `nonprod` | Network Test |
| `Workloads_Prod` | Production workloads | `prod` | Production apps |
| `Workloads_Test` | Test workloads | `nonprod` | Dev, staging apps |
| `Sandbox` | Experimental accounts | `nonprod` | Developer sandboxes |
| `Policy_Staging` | Policy testing | `nonprod` | Policy validation |
| `Suspended` | Suspended accounts | `nonprod` | Temporarily suspended |

### What You Control vs Module Automation

**Your Responsibilities:**
- Create accounts via AWS CLI first
- Define account-to-OU mapping in Terraform variables
- Choose project name and tagging strategy

**Module Handles Automatically:**
- Creates AWS SRA-compliant OU structure
- Places accounts in specified OUs
- Validates account configurations
- Provides clean outputs for SSO/Control Tower integration
- Follows AWS Security Reference Architecture patterns

## Service Configuration

Additional services are delegated, activated, and configured across the entire AWS Organization including:

- **AWS Organizations**: Organizational Units (OUs) following AWS SRA structure
- **IAM Identity Center**: Persona-based access control with group assignments
- GuardDuty
- Detective
- Inspector
- Security Hub
- Config
- CloudTrail

[AWS Security Services Best Practices](https://aws.github.io/aws-security-services-best-practices/) serves as a guide for the default configuration. Configurations for non-security services like AWS Config are also included to ensure compliance with the DoD Zero Trust strategy.

# Service Descriptions

## GuardDuty

Amazon GuardDuty is a threat detection service that continuously monitors for malicious activity and unauthorized behavior to protect your AWS accounts and workloads. GuardDuty is enabled in all accounts in the AWS Organization. The audit account is the master account for GuardDuty. Member accounts are enabled and configured to send findings to the master account.

## Detective

Amazon Detective makes it easy to analyze, investigate, and quickly identify the root cause of security findings or suspicious activities. Detective automatically collects log data from your AWS resources and uses machine learning, statistical analysis, and graph theory to help you visualize and conduct faster and more efficient security investigations.


## Inspector

Amazon Inspector is a vulnerability management service that continuously monitors your AWS workloads for software vulnerabilities and unintended network exposure. Amazon Inspector automatically discovers and scans running Amazon EC2 instances, container images in Amazon Elastic Container Registry (Amazon ECR), and AWS Lambda functions.


## Security Hub

AWS Security Hub provides you with a comprehensive view of your security state within AWS and helps you check your environment against security industry standards and best practices. Security Hub is enabled in all accounts in the AWS Organization. The audit account is the master account for Security Hub. Member accounts are enabled and configured to send findings to the master account.

## Config

AWS Config provides a detailed view of the resources associated with your AWS account, including how they are configured, how they are related to one another, and how the configurations and their relationships have changed over time. AWS Config resources provisioned by AWS Control Tower are tagged automatically with `aws-control-tower` and a value of `managed-by-control-tower`.

## CloudTrail

AWS Control Tower configures AWS CloudTrail to enable centralized logging and auditing for all accounts. With CloudTrail, the management account can review administrative actions and lifecycle events for member accounts.


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

For AWS GovCloud deployments, create accounts using the AWS CLI or API. **All accounts must exist before running this module.**

### Example: Creating GovCloud Accounts via CLI

```bash
# Set your management account profile
export AWS_PROFILE=your-govcloud-management-profile

# Create log archive account
aws organizations create-account \
  --email "log-archive@your-organization.gov" \
  --account-name "Security Log Archive" \
  --region us-gov-west-1

# Create audit account
aws organizations create-account \
  --email "audit@your-organization.gov" \
  --account-name "Security Audit" \
  --region us-gov-west-1

# Create network account
aws organizations create-account \
  --email "network@your-organization.gov" \
  --account-name "Infrastructure Network" \
  --region us-gov-west-1
```

### Account Naming Considerations

- **GovCloud Limitation**: Account names can only be changed from the paired commercial account
- **Module Behavior**: In GovCloud, this module automatically ignores account name changes to prevent failures
- **Best Practice**: Ensure account names in your configuration match the current names in the AWS Console

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

No action required.

If in the future you need to enroll/onboard new accounts to Control Tower, see these references:

- [Enroll an existing AWS account | AWS Docs](https://docs.aws.amazon.com/controltower/latest/userguide/enroll-account.html)
- [Field Notes: Enroll Existing AWS Accounts into AWS Control Tower | AWS Blogs](https://aws.amazon.com/blogs/architecture/field-notes-enroll-existing-aws-accounts-into-aws-control-tower/) for more information.


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
