# Control Tower Integration Strategy

## Overview

The modular architecture allows for flexible deployment patterns that can work with or without AWS Control Tower. The key is understanding what each service owns and how they can coexist.

## Control Tower vs Manual Management

### Critical Understanding: Landing Zone Manifest Controls Everything

The **landing zone manifest file** is the key to understanding Control Tower's flexibility. Here's what you need to know:

#### 🚨 **If you use the Landing Zone API with a manifest file:**
- ✅ **You CAN** specify existing OU names in `organizationStructure` (Security, Sandbox)
- ✅ **You CAN** disable SSO management with `"accessManagement": {"enabled": false}`
- ✅ **You CAN** use existing accounts for logging and security roles
- ✅ **You HAVE CONTROL** over what CT manages vs. what you self-manage

#### 🎯 **Key Insight from AWS Docs:**
> "After you choose to self-manage AWS IAM Identity Center as your IdP, AWS Control Tower creates only those roles and policies needed to manage AWS Control Tower, such as `AWSControlTowerAdmin` and `AWSControlTowerAdminPolicy`. For landing zones that self-manage, AWS Control Tower no longer creates IAM roles and groupings for customer-specific use."

### What Control Tower Manages (when accessManagement.enabled = true):
- ✅ Basic IAM Identity Center setup
- ✅ Default permission sets (AWS-managed)
- ✅ Service-linked roles for CT operations
- ✅ Organization service access principals
- ✅ Basic logging and compliance guardrails
- ✅ **Uses OUs you specify in manifest** (doesn't create new ones)

### What Control Tower Manages (when accessManagement.enabled = false):
- ✅ **Only** Control Tower admin roles and policies
- ✅ Organization service access principals
- ✅ Basic logging and compliance guardrails
- ✅ **Uses OUs you specify in manifest** (doesn't create new ones)
- 🚫 **Does NOT** manage IAM Identity Center resources

### What You Can Always Layer On Top:
- ✅ Custom permission sets with business logic
- ✅ Advanced persona-based group structures
- ✅ External identity provider integration (Entra ID)
- ✅ Fine-grained account-to-group mappings
- ✅ Additional OUs beyond CT requirements
- ✅ Enhanced security service configurations

## Recommended Configuration for Your Use Case

Based on your question, here's the **optimal approach** to use your existing Organizations module with Control Tower while self-managing SSO:

### 1. Update Control Tower Manifest Template

```json
{
  "governedRegions": ["us-gov-west-1", "us-gov-east-1"],
  "organizationStructure": {
    "security": {
      "name": "Security"  // Use YOUR existing Security OU name
    },
    "sandbox": {
      "name": "Sandbox"   // Use YOUR existing Sandbox OU name  
    }
  },
  "centralizedLogging": {
    "accountId": "${logging_account_id}",
    "configurations": {
      "loggingBucket": { "retentionDays": 913 },
      "accessLoggingBucket": { "retentionDays": 913 },
      "kmsKeyArn": "${kms_key_arn}"
    },
    "enabled": true
  },
  "securityRoles": {
    "accountId": "${security_account_id}"
  },
  "accessManagement": {
    "enabled": false  // 🎯 KEY: This disables CT's SSO management
  }
}
```

### 2. Deployment Sequence

```hcl
# Step 1: Deploy Organizations module first
module "organizations" {
  source = "./modules/organizations"
  
  # Creates your Security, Sandbox, and other OUs
  # Creates your accounts with proper naming
}

# Step 2: Deploy Control Tower with self-managed SSO
module "controltower" {
  source = "./modules/controltower"
  depends_on = [module.organizations]
  
  # Uses existing OUs created by organizations module
  # Uses existing accounts for logging/security roles
  # Does NOT manage SSO (accessManagement.enabled = false)
}

# Step 3: Deploy your SSO module with full control
module "sso" {
  source = "./modules/sso"
  depends_on = [module.controltower]
  
  auto_detect_control_tower = true    # Still detects CT for awareness
  enable_sso_management = true        # But YOU manage SSO completely
  
  # Your persona-based access control
  # Your Entra ID integration
  # Your custom permission sets
}
```

### 3. Benefits of This Approach

- ✅ **No Resource Conflicts**: CT doesn't touch SSO when `accessManagement.enabled = false`
- ✅ **Use Existing OUs**: CT uses your pre-existing Security/Sandbox OUs
- ✅ **Full SSO Control**: Your SSO module has complete management authority
- ✅ **CT Benefits**: Still get guardrails, logging, compliance baseline
- ✅ **Future Flexibility**: Can toggle `accessManagement.enabled = true` later if needed

### 4. Updated SSO Module Logic

```hcl
# In your SSO module - this logic changes slightly:
locals {
  control_tower_detected = length([
    for principal in data.aws_organizations_organization.current[0].aws_service_access_principals :
    principal if principal == "controltower.amazonaws.com"
  ]) > 0
  
  # With accessManagement.enabled = false, you can always manage SSO
  # even when CT is present - because CT isn't managing SSO
  sso_management_enabled = var.enable_sso_management  // No CT conflict when self-managed
}
```

## Deployment Patterns

### Pattern 1: Green-field with Control Tower (Recommended)
```hcl
# Deploy in this order:
# 1. Organizations module (creates OUs, manages accounts)
# 2. Control Tower module (deploys landing zone)
# 3. SSO module (with auto-detection, adds custom permission sets)
# 4. Security services modules (GuardDuty, etc.)

module "organizations" {
  source = "./modules/organizations"
  # Creates OUs, manages account placement
  
  organizational_units = {
    Security            = { lifecycle = "prod", tags = {} }
    Infrastructure_Prod = { lifecycle = "prod", tags = {} }
    Workloads_Prod     = { lifecycle = "prod", tags = {} }
    # Additional OUs beyond CT defaults
  }
}

module "controltower" {
  source = "./modules/controltower"
  depends_on = [module.organizations]
  
  account_id_map = module.organizations.account_id_map
  # Deploys Control Tower landing zone v3.3
}

module "sso" {
  source = "./modules/sso"
  depends_on = [module.controltower]
  
  auto_detect_control_tower = true  # Automatically detects CT
  enable_sso_management = true      # Adds custom permission sets on top of CT
  
  # Custom persona-based permission sets beyond CT defaults
  account_role_mapping = {
    "Security Audit" = "audit"
    "Log Archive"    = "log_archive"
    "Network Hub"    = "network"
  }
}

# Additional security services
module "guardduty" {
  source = "./modules/guardduty"
  depends_on = [module.controltower]
}
```

### Pattern 2: Existing Control Tower Environment
```hcl
# For environments where CT is already deployed
module "organizations" {
  source = "./modules/organizations"
  
  # Import existing accounts/OUs created by CT
  aws_organization_id = "o-existing-ct-org"
}

module "sso" {
  source = "./modules/sso"
  
  auto_detect_control_tower = true
  enable_sso_management = true      # Can still add custom permission sets
  enable_entra_integration = true   # External IdP integration
  
  # Layered persona management on top of CT
  account_role_mapping = {
    "Management"     = "management"
    "Security Audit" = "audit"
    "Log Archive"    = "log_archive"
  }
}
```

### Pattern 3: No Control Tower (Direct Management)
```hcl
# Full manual control without Control Tower
module "organizations" {
  source = "./modules/organizations"
}

module "sso" {
  source = "./modules/sso"
  
  auto_detect_control_tower = false
  enable_sso_management = true      # Full SSO management
  
  # Complete persona-based access control
}

# Manual CSPM service configuration
module "guardduty" { ... }
module "securityhub" { ... }
```

## Control Tower Detection Logic

The SSO module now automatically detects Control Tower by:

1. **Service Principal Detection**: Checks for `controltower.amazonaws.com` in organization service access principals
2. **Automatic Adjustment**: Disables conflicting SSO management if CT detected
3. **Layered Approach**: Still allows custom permission sets and external IdP integration

```hcl
# In the SSO module
locals {
  control_tower_detected = length([
    for principal in data.aws_organizations_organization.current[0].aws_service_access_principals :
    principal if principal == "controltower.amazonaws.com"
  ]) > 0
  
  # Smart enablement - work with CT, not against it
  sso_management_enabled = var.auto_detect_control_tower ? 
    (local.control_tower_detected ? false : var.enable_sso_management) : 
    var.enable_sso_management
}
```

## Service Integration Considerations

### GuardDuty with Control Tower:
- ✅ CT enables GuardDuty in delegated admin pattern
- ✅ Your module can enhance configuration (custom threat feeds, etc.)
- ⚠️ Don't conflict with CT's delegation

### Security Hub with Control Tower:
- ✅ CT enables Security Hub with baseline standards
- ✅ Your module can add custom standards and insights
- ⚠️ Coordinate finding aggregation

### Config with Control Tower:
- ✅ CT deploys baseline Config rules
- ✅ Your module can add custom compliance rules
- ⚠️ Don't duplicate delivery channels

## Recommended Approach for Complete Landing Zone

```hcl
# Complete secure landing zone with Control Tower harmony
module "organizations" {
  source = "./modules/organizations"
  # Foundational account and OU management
}

module "controltower" {
  source     = "./modules/controltower"
  depends_on = [module.organizations]
  # Control Tower baseline (guardrails, logging, basic SSO)
}

module "sso" {
  source     = "./modules/sso"
  depends_on = [module.controltower]
  
  auto_detect_control_tower = true
  # Persona-based access control layered on CT foundation
}

module "cspm" {
  source     = "./modules/cspm"
  depends_on = [module.controltower]
  # Enhanced security posture on CT foundation
}
```

## Summary: Your Specific Question Answered

### ✅ **YES, you can do exactly what you want:**

1. **Use your existing Security and Sandbox OUs**: Control Tower's `organizationStructure` in the manifest simply **references** existing OU names - it doesn't create new ones if they already exist.

2. **Self-manage SSO completely**: Set `"accessManagement": {"enabled": false}` in the landing zone manifest, and Control Tower will NOT touch IAM Identity Center resources.

3. **Pass in your existing OUs**: The manifest's `organizationStructure.security.name` and `organizationStructure.sandbox.name` should match your existing OU names exactly.

4. **Deploy in sequence**: Organizations → Control Tower → SSO works perfectly with this configuration.

### 🔑 **Key Insight**: 
The landing zone manifest file gives you **complete control** over what Control Tower manages. With `accessManagement.enabled = false`, you get:
- ✅ Control Tower's guardrails and compliance baseline
- ✅ Control Tower's logging and CloudTrail setup  
- ✅ Control Tower's service integrations
- 🚫 **Zero** IAM Identity Center resource management by Control Tower

### 📋 **Your Deployment Checklist**:
- [ ] Update Control Tower manifest template with `"accessManagement": {"enabled": false}`
- [ ] Ensure manifest references your existing "Security" and "Sandbox" OU names
- [ ] Deploy organizations module first (creates OUs and accounts)
- [ ] Deploy Control Tower module with `self_managed_sso = true`  
- [ ] Deploy SSO module with `enable_sso_management = true`
- [ ] Enjoy the best of both worlds! 🎉

## Benefits of This Approach

1. **Best of Both Worlds**: CT's baseline + your customizations
2. **Conflict Avoidance**: Automatic detection prevents resource conflicts
3. **Incremental Enhancement**: Add value without replacing CT
4. **Future-Proof**: Can migrate to/from CT without complete rewrites
5. **Compliance Ready**: CT handles baseline, you add specific requirements

## Module Architecture Overview

The CSPM module implements a layered architecture with clear separation of concerns:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Organizations │────│  Control Tower   │────│      SSO        │
│                 │    │                  │    │                 │
│ • Account Mgmt  │    │ • Landing Zone   │    │ • Access Mgmt   │
│ • OU Structure  │    │ • Guardrails     │    │ • Permission    │
│ • SRA Compliance│    │ • Baseline       │    │   Sets          │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────────┐
                    │ Security Services  │
                    │                    │
                    │ • GuardDuty        │
                    │ • Security Hub     │
                    │ • Inspector2       │
                    │ • Detective        │
                    │ • Config           │
                    └─────────────────────┘
```

### Key Architecture Features

- **DISA SCCA Compliance**: Implements cloud-native SCCA patterns
- **AWS SRA Integration**: Follows AWS Security Reference Architecture
- **Multi-Partition Support**: Works with both Commercial AWS and GovCloud
- **Zero Trust Ready**: Designed for DoD Zero Trust implementation
- **Modular Design**: Clean separation of concerns between modules
- **Account Import**: Manages existing accounts without recreation

### Account Organization Patterns

#### Required Account Types
- **management**: AWS Organization management account (Root OU)
- **log_archive**: Central logging account (Security OU)
- **audit**: Security audit account (Security OU)

#### Standard OUs (AWS SRA)
- **Security**: Security and compliance accounts
- **Infrastructure_Prod/NonProd**: Network and shared services
- **Workloads_Prod/NonProd**: Application workloads
- **Sandbox**: Development and experimentation
- **Policy_Staging**: Policy testing
- **Suspended**: Decommissioned accounts

#### Account Naming Convention
```
{Organization}-{Function}-{Environment}
Examples:
- "ACME-Management"
- "ACME-Security-Audit" 
- "ACME-Workload-App1-Prod"
```
