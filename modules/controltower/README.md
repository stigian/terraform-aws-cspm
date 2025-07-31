
# Control Tower Module

## Overview

This module deploys AWS Control Tower Landing Zone with enhanced security features for DoD Zero Trust CSPM environments. It establishes governance guardrails, centralized logging, and automated account provisioning while integrating with organizational KMS infrastructure.

**Key Architecture Pattern**: Conditional landing zone deployment with `deploy_landing_zone` flag - allows KMS-only setup for manual Control Tower configuration or integration with existing Control Tower deployments.

## Architecture Pattern

### Landing Zone Foundation
- **Control Tower Deployment**: Optional full landing zone with guardrails and baseline controls
- **KMS Integration**: Enhanced encryption with organizational boundaries and SSO-aware policies
- **Multi-Account Governance**: Automated guardrails across Security, Workloads, and Sandbox OUs
- **Partition Support**: Automatically handles Commercial and GovCloud deployment differences

### Resource Management Strategy
When `deploy_landing_zone = true`:
- Creates complete Control Tower landing zone with required IAM roles
- Deploys organizational guardrails and baseline security controls
- Establishes centralized CloudTrail and Config configuration
- Requires management, log_archive, and audit account IDs

When `deploy_landing_zone = false`:
- Creates only KMS resources for Control Tower integration
- Allows manual Control Tower setup or integration with existing deployments
- Supports scenarios where Control Tower is managed outside Terraform

### SSO Integration Features
- **Self-Managed SSO**: Default `self_managed_sso = true` disables Control Tower SSO management
- **KMS Policy Integration**: Automatically includes SSO Administrator role ARNs in KMS policies
- **Role-Based Access**: Supports additional KMS admin ARNs for specific users and roles

## Deployment Requirements

### Prerequisites
1. **Account Structure**: Requires existing management, log_archive, and audit accounts (from Organizations module)
   ```hcl
   module "controltower" {
     source = "./modules/controltower"
     
     management_account_id   = "123456789012"  # From organizations output
     log_archive_account_id  = "123456789013"  # From organizations output  
     audit_account_id        = "123456789014"  # From organizations output
   }
   ```

2. **IAM Permissions**: Management account must have Control Tower service permissions
3. **Regional Requirements**: Must deploy in Control Tower supported regions (us-east-1, us-gov-west-1, etc.)

### Configuration Variables
- **`deploy_landing_zone`**: Boolean controlling full deployment vs KMS-only mode
- **`self_managed_sso`**: Boolean disabling Control Tower SSO management (default: true)
- **`additional_kms_key_admin_arns`**: List of additional IAM ARNs for KMS administration
- **Required Account IDs**: management_account_id, log_archive_account_id, audit_account_id

### Provider Requirements
```hcl
provider "aws" {
  region  = "us-gov-west-1"  # GovCloud deployments
  profile = "management-account-profile"
}
```

## Troubleshooting

### Landing Zone Deployment Issues
1. **Previous Control Tower Cleanup**: Manual cleanup required if Control Tower was previously decommissioned
2. **Account Validation Failures**: Verify account IDs are 12-digit strings and accounts exist
3. **Regional Constraints**: Ensure deployment region supports Control Tower (limited regions available)

### KMS Key Management Problems
- **Policy Conflicts**: Check additional_kms_key_admin_arns for valid IAM ARN format
- **SSO Integration Issues**: Verify SSO Administrator roles exist when self_managed_sso = true
- **Cross-Account Access**: Ensure organizational boundaries allow intended account access

### Role Creation Failures
```hcl
# Check for existing roles that may conflict
aws iam get-role --role-name AWSControlTowerServiceRoleForManagement
```

## Integration with Other Modules

### Organizations Module Integration
- **Account Requirements**: Consumes management, log_archive, and audit account IDs from organizations outputs
- **OU Coordination**: Works with organizations module to establish Security and Sandbox OUs
- **Foundation Dependency**: Must deploy after organizations module establishes account structure

### SSO Module Integration
- **Self-Managed Mode**: Default configuration allows SSO module to manage IAM Identity Center independently
- **KMS Policy Integration**: Automatically includes SSO Administrator roles in KMS key policies
- **Access Management**: Supports SSO-based access patterns for Control Tower administration

### Security Services Integration
- **Centralized Logging**: Provides CloudTrail foundation for security service monitoring
- **Config Integration**: Establishes configuration compliance baseline for security services
- **Audit Account Foundation**: Supports audit account as delegated administrator for security services

## DoD-Specific Considerations

### GovCloud Deployment Patterns
- **Partition Detection**: Automatically adjusts ARN formats and service availability for GovCloud
- **Regional Limitations**: Supports us-gov-west-1 and us-gov-east-1 Control Tower availability
- **Compliance Controls**: Implements Control Tower guardrails aligned with DoD security requirements

### Enterprise Security Features
- **Enhanced KMS Security**: Organizational boundaries prevent cross-organization access
- **SSO-Aware Policies**: Integrates with enterprise identity management patterns
- **Audit Trail Integration**: Supports DoD audit and compliance reporting requirements

### Operational Constraints
- **Landing Zone Lifecycle**: Control Tower landing zones cannot be easily destroyed - requires careful planning
- **Manual Integration Points**: Some Control Tower features require manual configuration outside Terraform
- **Service Role Management**: Control Tower service roles created with specific organizational permissions

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_controltower_landing_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/controltower_landing_zone) | resource |
| [aws_iam_role.controltower_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.controltower_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.controltower_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.controltower_stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.controltower_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.controltower_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.controltower_stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.controltower_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.controltower_config_organizations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.control_tower](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.control_tower](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.control_tower](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_kms_key_admin_arns"></a> [additional\_kms\_key\_admin\_arns](#input\_additional\_kms\_key\_admin\_arns) | Optional list of additional IAM ARNs that will be granted KMS key administrative permissions.<br/><br/>Use this to grant KMS admin access to specific users, roles, or external accounts beyond the default admins:<br/>- Current Terraform caller<br/>- SSO Administrator roles<br/>- Project-specific admin roles<br/><br/>Example: ["arn:aws-us-gov:iam::123456789012:user/admin", "arn:aws-us-gov:iam::123456789012:role/SecurityTeam"] | `list(string)` | `[]` | no |
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | Account ID for the Control Tower audit account. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where resources will be created. Auto-detected from provider if not specified. | `string` | `null` | no |
| <a name="input_deploy_landing_zone"></a> [deploy\_landing\_zone](#input\_deploy\_landing\_zone) | Whether to deploy the AWS Control Tower Landing Zone.<br/><br/>When true: Deploys full Control Tower landing zone with guardrails and baseline controls<br/>When false: Only creates KMS resources, allowing manual Control Tower setup or existing setup<br/><br/>REQUIREMENT: If true, you must provide management\_account\_id, log\_archive\_account\_id, and audit\_account\_id | `bool` | `true` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Tags applied to all resources created by this module. | `map(string)` | <pre>{<br/>  "ManagedBy": "opentofu"<br/>}</pre> | no |
| <a name="input_log_archive_account_id"></a> [log\_archive\_account\_id](#input\_log\_archive\_account\_id) | Account ID for the Control Tower log archive account. | `string` | n/a | yes |
| <a name="input_management_account_id"></a> [management\_account\_id](#input\_management\_account\_id) | Account ID for the AWS Organization management account. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of the project or application. Used for resource naming and tagging. | `string` | `"CnScca"` | no |
| <a name="input_self_managed_sso"></a> [self\_managed\_sso](#input\_self\_managed\_sso) | Whether to use self-managed SSO (accessManagement.enabled = false in manifest). When true, Control Tower will not manage IAM Identity Center resources, allowing you to manage SSO independently. Defaults to true as terraform-aws-cspm provides its own SSO module for lifecycle management. | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
   - Organization-scoped KMS key for Control Tower resources
   - SSO-aware key policies with precise role matching
   - Management account restricted access patterns
   - Automatic key rotation enabled

3. **Security Boundaries**
   - `aws:PrincipalOrgID` conditions for organizational isolation
   - SSO role-based access patterns (`${project}-aws-admin`)
   - Management account scope restrictions
   - Cross-partition compatibility

---

## AWS SRA Compliance

This module implements AWS Security Reference Architecture patterns:

### Required Account Structure

| Account Type | Purpose | OU Placement | Required |
|--------------|---------|--------------|-----------|
| **Management** | Organization management, billing, Control Tower | Root | ✅ Yes |
| **Log Archive** | Centralized logging, CloudTrail, Config | Security | ✅ Yes |
| **Audit** | Security audit, compliance monitoring | Security | ✅ Yes |

### Security Guardrails

- **Preventive Guardrails**: Block non-compliant actions
- **Detective Guardrails**: Alert on suspicious activities  
- **Proactive Guardrails**: Automatically remediate issues
- **Data Residency**: Ensure data stays within approved regions

---

## Quick Start

### Minimal Configuration

```hcl
module "controltower" {
  source = "../modules/controltower"
  
  # Required: Core account IDs for Control Tower
  management_account_id  = "123456789012"
  log_archive_account_id = "234567890123"
  audit_account_id       = "345678901234"
  
  # Optional: Control deployment
  deploy_landing_zone = true
  self_managed_sso    = true
  
  # Optional: Customization
  project     = "myorg"
  aws_region  = "us-west-2"
  global_tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### Integration with Organizations Module

```hcl
module "organizations" {
  source = "../modules/organizations"
  
  project                = "myorg"
  aws_account_parameters = var.aws_account_parameters
}

module "controltower" {
  source = "../modules/controltower"
  
  # Clean integration using organizations output
  management_account_id  = module.organizations.management_account_id
  log_archive_account_id = module.organizations.log_archive_account_id
  audit_account_id       = module.organizations.audit_account_id
  
  project    = module.organizations.project
  global_tags = module.organizations.global_tags
}
```

---

## Configuration Options

### Landing Zone Control

```hcl
# Deploy new Control Tower Landing Zone
deploy_landing_zone = true

# Use existing Control Tower (management only)
deploy_landing_zone = false
```

### SSO Integration

```hcl
# Let Control Tower manage SSO
self_managed_sso = false

# Manage SSO separately (with sso module)
self_managed_sso = true
```

### KMS Security Enhancement

The module automatically creates enhanced KMS keys with:

- **Organizational Boundaries**: `aws:PrincipalOrgID` conditions
- **SSO Role Integration**: Precise role matching patterns
- **Management Account Scope**: Restricted to management account operations
- **Automatic Rotation**: Enabled by default

---

## Integration Patterns

### Pattern 1: Full Stack Deployment

```hcl
# Complete landing zone with all modules
module "organizations" {
  source = "../modules/organizations"
  aws_account_parameters = var.aws_account_parameters
}

module "controltower" {
  source = "../modules/controltower"
  
  management_account_id  = module.organizations.management_account_id
  log_archive_account_id = module.organizations.log_archive_account_id
  audit_account_id       = module.organizations.audit_account_id
}

module "sso" {
  source = "../modules/sso"
  
  project                = module.organizations.project
  account_id_map         = module.organizations.account_id_map
  auto_detect_control_tower = true
}
```

### Pattern 2: Control Tower Only

```hcl
# Deploy just Control Tower with hardcoded account IDs
module "controltower" {
  source = "../modules/controltower"
  
  management_account_id  = "123456789012"
  log_archive_account_id = "234567890123" 
  audit_account_id       = "345678901234"
  
  deploy_landing_zone = true
}
```

### Pattern 3: External Data Sources

```hcl
# Use external data sources for account IDs
data "aws_ssm_parameter" "account_ids" {
  for_each = toset(["management", "log_archive", "audit"])
  name     = "/company/aws/${each.key}-account-id"
}

module "controltower" {
  source = "../modules/controltower"
  
  management_account_id  = data.aws_ssm_parameter.account_ids["management"].value
  log_archive_account_id = data.aws_ssm_parameter.account_ids["log_archive"].value
  audit_account_id       = data.aws_ssm_parameter.account_ids["audit"].value
}
```

---

## Troubleshooting

### Common Issues

**Issue**: `Invalid value for variable` - account ID validation
```
Error: Management account ID must be a 12-digit string.
```
**Solution**: Ensure account IDs are exactly 12 digits without spaces or dashes.

**Issue**: Control Tower deployment timeout
```
Error: timeout while waiting for state to become 'SUCCEEDED'
```
**Solution**: Control Tower deployment can take 60+ minutes. Increase timeout or check AWS console for progress.

**Issue**: KMS key policy conflicts
```
Error: AccessDenied when creating KMS key policy
```
**Solution**: Ensure you're running from the management account with appropriate permissions.

### Prerequisites Checklist

- [ ] Running from AWS management account
- [ ] Organization created and configured
- [ ] Required accounts (management, log archive, audit) exist
- [ ] Accounts have correct AccountType tags (if using organizations module)
- [ ] AWS CLI/Provider configured with appropriate permissions
- [ ] No existing Control Tower deployment (unless `deploy_landing_zone = false`)

### Validation Commands

```bash
# Verify account IDs are accessible
aws sts get-caller-identity

# Verify organization status
aws organizations describe-organization

# Check Control Tower service status
aws controltower get-landing-zone --landing-zone-identifier <id>
```

---

## Security Considerations

### KMS Key Security

The module creates KMS keys with enhanced security:

- **Organizational Boundaries**: Keys only usable within your organization
- **SSO Integration**: Precise role-based access patterns
- **Management Account Restriction**: Control Tower operations scoped appropriately
- **Audit Logging**: All key usage logged to CloudTrail

### Network Security

- **Regional Isolation**: Resources deployed in specified region only
- **Cross-Partition Support**: Handles commercial vs GovCloud differences
- **Service Integration**: Secure integration with AWS native services

### Access Patterns

- **Least Privilege**: Minimal required permissions for Control Tower operation
- **Role-Based Access**: Integration with SSO role patterns
- **Audit Trail**: Complete logging of all administrative actions

---

## Advanced Configuration

### Custom KMS Key Policies

```hcl
# The module automatically creates secure KMS policies
# No additional configuration needed for standard deployments
```

### Multi-Region Considerations

```hcl
# Control Tower is region-specific
# Deploy in your primary governance region
aws_region = "us-gov-west-1"  # GovCloud
aws_region = "us-east-1"      # Commercial (recommended)
```

### Compliance Integration

```hcl
# Module integrates with compliance frameworks
global_tags = {
  Compliance    = "FedRAMP"
  Classification = "CUI"
  Environment   = "production"
}
```

---

## Troubleshooting

### Pre-deployment Validation

Before deploying this module, especially after a previous Control Tower decommissioning, ensure:

1. **No Security/Sandbox OUs** at organization root level
2. **No Control Tower IAM roles** remain in management account
3. **No reserved S3 buckets** exist in logging account
4. **No CloudWatch log groups** named `aws-controltower/CloudTrailLogs`

**Complete troubleshooting guide**: [Control Tower Troubleshooting Guide](../../docs/control-tower-troubleshooting.md)

### Common Issues

- **"ValidationException: could not assume AWSControlTowerAdmin role"**: Control Tower service roles missing
- **S3 bucket "already exists" errors**: Previous deployment left reserved bucket names
- **Permission denied errors**: Cross-account providers not configured properly

### Emergency Recovery

```bash
# Check landing zone status
aws controltower list-landing-zones --region us-gov-west-1

# Remove from Terraform state if needed
tofu state rm "module.controltower.aws_controltower_landing_zone.this[0]"
```

---

## Resources Created by Control Tower

**Note**: Control Tower creates numerous resources automatically. See the [official Control Tower documentation](https://docs.aws.amazon.com/controltower/latest/userguide/shared-account-resources.html) for a complete list.

### Key Resources Include:

- CloudFormation StackSets for account baselines
- AWS Config rules and conformance packs
- AWS CloudTrail organization trail
- Amazon S3 buckets for logging and access logging
- AWS Lambda functions for automation
- IAM roles and policies for service integration
- Amazon SNS topics for notifications
- AWS Service Catalog portfolios for account vending

### Module-Created Resources:

- `aws_controltower_landing_zone` - Main Control Tower deployment
- `aws_kms_key.control_tower` - Enhanced KMS key for encryption
- `aws_kms_alias.control_tower` - Friendly alias for KMS key
- `aws_kms_key_policy.control_tower` - Security-enhanced key policy