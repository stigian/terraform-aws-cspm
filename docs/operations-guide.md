# Operations Guide - Daily Tasks

This guide covers common operational tasks for the terraform-aws-cspm module. Designed for operators who need to perform routine maintenance and updates.

---

## 🔧 Daily Operations

### Account Management

#### Adding New AWS Accounts
**Prerequisites**: AWS CLI configured with management account access

```bash
# 1. Create account via CLI (REQUIRED FIRST STEP)
# GovCloud example:
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-NewDept-Prod" \
  --email "aws-newdept@yourorg.com" \
  --profile cnscca-gov-mgmt

# 2. Wait for account creation (can take 15+ minutes)
aws organizations list-accounts --query 'Accounts[?Name==`YourOrg-NewDept-Prod`]'

# 3. Add to terraform configuration
# Edit examples/config/accounts.yaml or terraform.tfvars
```

**Configuration Example**:
```yaml
# In examples/config/accounts.yaml
accounts:
  "123456789012":
    name: "YourOrg-NewDept-Prod"     # EXACT name from CLI
    email: "aws-newdept@yourorg.com" # EXACT email from CLI
    ou: "Workloads_Prod"             # Target OU
    lifecycle: "prod"                # prod or nonprod
    account_type: "workload"         # See config/sra-account-types.yaml
```

#### Moving Accounts Between OUs
```bash
# 1. Update configuration
# Change 'ou' field in accounts.yaml or terraform.tfvars

# 2. Plan and apply
cd examples/
tofu plan
tofu apply
```

### Organizational Unit Management

#### Adding New OUs
**No code changes required!** Just update configuration:

```yaml
# In examples/config/organizational_units.yaml
organizational_units:
  # Standard OUs...
  Development:
    lifecycle: "nonprod"
    description: "Development and testing environments"
  
  # Your new OU
  Staging:
    lifecycle: "nonprod" 
    description: "Staging environment for testing"
```

**Reference**: [Complete OU extension guide](./extending-ous-and-lifecycles.md)

### SSO User Management

#### Adding New SSO Users
```bash
# 1. Log into AWS Console → IAM Identity Center
# 2. Add user through console interface
# 3. Note the User ID for admin assignment

# 4. Update terraform configuration
# In examples/main.tf, update existing_admin_user_id or add to initial_admin_users
```

#### Creating Permission Sets
```hcl
# Permission sets are auto-created based on account_type
# Standard sets: aws-admin, read-only, security-admin, network-admin
# Custom sets can be added in modules/sso/main.tf
```

### Control Tower Operations

#### Checking Landing Zone Status
```bash
# List landing zones
aws controltower list-landing-zones --region us-gov-west-1

# Check operation status  
aws controltower list-landing-zone-operations --region us-gov-west-1

# Get operation details
aws controltower get-landing-zone-operation \
  --operation-identifier "operation-id" \
  --region us-gov-west-1
```

#### Emergency Control Tower Recovery
```bash
# If Control Tower deployment fails:

# 1. Remove from Terraform state
tofu state rm "module.controltower.aws_controltower_landing_zone.this[0]"

# 2. Clean up AWS resources (if needed)
# See: docs/control-tower-troubleshooting.md

# 3. Retry deployment
tofu plan
tofu apply
```

---

## 🛡️ Security Operations

### Monitoring and Compliance

#### Checking Account Compliance
```bash
# View Config compliance
aws configservice describe-compliance-by-config-rule \
  --region us-gov-west-1

# View Security Hub findings
aws securityhub get-findings \
  --region us-gov-west-1 \
  --max-results 10
```

#### Reviewing SSO Access
```bash
# List permission sets
aws sso-admin list-permission-sets \
  --instance-arn $(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text)

# List account assignments
aws sso-admin list-account-assignments \
  --instance-arn $(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text) \
  --account-id "123456789012" \
  --permission-set-arn "permission-set-arn"
```

### Cross-Account Security Services

#### Enabling GuardDuty for New Accounts
```hcl
# Add to main.tf when ready:
module "guardduty" {
  source = "../modules/guardduty"
  
  audit_account_id = module.yaml_transform.audit_account_id
  global_tags      = module.yaml_transform.global_tags
  
  depends_on = [module.organizations]
}
```

---

## 🚨 Troubleshooting

### Common Issues & Solutions

#### Validation Errors
```bash
# Error: "Invalid account type"
# Solution: Check config/sra-account-types.yaml for valid values

# Error: "OU does not exist"  
# Solution: Verify OU name matches organizational_units configuration

# Error: "Account not found"
# Solution: Ensure account was created via CLI first
```

#### Provider Authentication Issues
```bash
# Error: "User does not have permissions to access account data"
# Solution: Verify OrganizationAccountAccessRole exists in target accounts

# Check role exists:
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/OrganizationAccountAccessRole" \
  --role-session-name "test-session" \
  --profile cnscca-gov-mgmt
```

#### State Management Issues
```bash
# View current state
tofu state list

# Remove problematic resources
tofu state rm "resource.name"

# Import existing resources
tofu import "resource.name" "resource-id"
```

### Validation Commands

```bash
# Basic validation
tofu validate
tofu plan

# Check AWS connectivity
aws sts get-caller-identity

# Verify organization
aws organizations describe-organization

# Check account access
aws sts assume-role \
  --role-arn "arn:aws:iam::ACCOUNT-ID:role/OrganizationAccountAccessRole" \
  --role-session-name "validation"
```

---

## 📋 Maintenance Checklist

### Daily
- [ ] Monitor Control Tower operation status (if deploying)
- [ ] Check Security Hub findings for critical issues
- [ ] Review CloudTrail for unusual activity

### Weekly  
- [ ] Review Config compliance status
- [ ] Verify SSO user access patterns
- [ ] Check for new AWS service updates

### Monthly
- [ ] Review account OU placement
- [ ] Update documentation for new procedures
- [ ] Test emergency recovery procedures
- [ ] Review and rotate access keys

### Quarterly
- [ ] Review and update permission sets
- [ ] Audit cross-account role usage
- [ ] Update operational runbooks
- [ ] Review compliance posture

---

## 📞 Escalation Procedures

### Level 1 - Self-Service
- Check this operations guide
- Review module-specific READMEs
- Use troubleshooting commands above

### Level 2 - Documentation Review
- [Control Tower Troubleshooting](./control-tower-troubleshooting.md)
- [Account Management Guide](./account-management-guide.md)
- [Integration Strategy](./integration-strategy.md)

### Level 3 - AWS Support
- Gather terraform state information
- Collect AWS CLI output from validation commands
- Document exact error messages and timestamps
- Include operation IDs for Control Tower issues

---

*Last Updated: July 2025*  
*For updates to this guide, please submit a pull request or create an issue.*
