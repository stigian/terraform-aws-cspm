# Operations Guide

**Daily operations and maintenance procedures** for terraform-aws-cspm modular security architecture.


## Operations Task Schedule

> [!NOTE]
> The following schedule is a recommended baseline. Actual tasks and access requirements may vary based on your organization's authorization policies and assigned roles. Always follow your team's procedures and consult the appropriate dashboard or documentation for each check.

**Daily Operations:**
- Review GuardDuty findings in the audit account Security Hub dashboard, check for new findings, triage alerts, and escalate critical issues
- Check Control Tower compliance dashboard for guardrail status to identify noncompliant resources
- Monitor ongoing deployments in your CI/CD system (Review tofu apply results, investigate failed jobs, track deployment history)
- Verify new account compliance (Confirm account appears in correct OU, validate GuardDuty and Config enrollment, check SSO access)

**Weekly Operations:**
- Review SSO access patterns in IAM Identity Center, audit recent logins, identify unused accounts, review permission set assignments
- Update documentation as needed (internal wiki or repo), add new account details, update onboarding steps, revise operational checklists
- Review Config compliance scores and remediate violations in AWS Config, address failed rules, document remediation steps, assign owners for fixes

**Monthly Operations:**
- Complete security access reviews in IAM Identity Center
- Update Terraform modules and dependencies in your repo
- Review CloudTrail log integrity and coverage in CloudTrail console
- Quantify compliance metrics and posture trends in Control Tower dashboard

**Quarterly Operations:**
- Perform comprehensive security audit
- Update disaster recovery procedures and runbooks
- Plan major architecture changes with stakeholders

For detailed security operations, incident response, and compliance workflows, refer to the [Security Team Guide](./security.md).

Other common operations (as needed):
- Add new account: CLI creation → YAML config → Deploy
- Manage SSO access: IAM Identity Center console
- Add new OU: Update YAML config → Deploy

Refer to the [Security Team Guide](./security.md) for security-specific operational details.

### Module Overview

| Module | Purpose | Operational Notes |
|--------|---------|-------------------|
| organizations  | Account placement, OU structure  | Rarely needs changes after initial setup|
| controltower   | Governance baseline              | Monitor guardrails, handle violations   |
| sso            | Identity & access control        | User assignments, group management      |
| guardduty      | Threat detection                 | Daily finding reviews, tune protection plans |
| detective      | Security investigation           | Use for incident response               |
| securityhub    | Centralized security findings    | Weekly compliance reports               |
| awsconfig      | Configuration compliance         | Monitor drift, handle violations        |
| inspector2     | Vulnerability management         | Regular scans, report findings          |


## Account Management

### Adding New AWS Accounts

#### Step 1: Create Account via AWS CLI (Required First)
```bash
# GovCloud (most common for DoD environments)
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Workloads-NewApp" \
  --email "aws-newapp@yourorg.com" \
  --profile your-management-profile

# Commercial AWS
aws organizations create-account \
  --account-name "YourOrg-Workloads-NewApp" \
  --email "aws-newapp@yourorg.com" \
  --profile your-management-profile

# Record the account ID from the response
```

#### Step 2: Add to YAML Configuration
Add new account to appropriate YAML file in `examples/inputs/accounts.yaml`:

```yaml
# -- inputs/accounts.yaml --
new_application_account:
  account_id: "NEW_ACCOUNT_ID"             # From CLI response
  account_name: "YourOrg-Workloads-NewApp" # Exact CLI name
  email: "aws-newapp@yourorg.com"          # Exact CLI email
  account_type: workload                   # Determines SSO permissions
  ou: Workloads_Prod                       # Target OU
  lifecycle: prod                          # prod or nonprod
  additional_tags:
    Department: "Engineering"
    Application: "NewApp"
    Owner: "Development Team"
```

#### Step 3: Deploy Changes
```bash
tofu plan    # Review account placement
tofu apply   # Deploy account to organization
```

#### Step 4: Verify Deployment
```bash
# Check account placement
aws organizations list-accounts-for-parent --parent-id ou-xxxxx

# Verify security services enrollment (may take 5-10 minutes)
# Login to audit account and check:
# - GuardDuty: Account appears in member accounts
# - Detective: Account enrolled in behavior graph
# - Security Hub: Account shows in organization view
```

### Account Lifecycle Management

#### Moving Accounts Between OUs
```yaml
# Update the account's OU in YAML configuration
existing_account:
  # ... other config unchanged
  ou: Workloads_NonProd  # Changed from Workloads_Prod
```

Then deploy: `tofu apply`

#### Updating Account Classifications
```yaml
# Change account type (affects SSO permissions)
existing_account:
  # ... other config unchanged
  account_type: sandbox  # Changed from workload
  lifecycle: nonprod     # Update lifecycle to match
```

#### Removing/Suspending Accounts

> [!IMPORTANT]
> **Account Closure**: This process only removes accounts from organizational management. To actually close an AWS account, you must follow the [AWS account closure process](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/Closing-govcloud-account.html) separately.

```yaml
# Move to suspended OU for deactivation
suspended_account:
  # ... other config unchanged
  ou: Suspended
  lifecycle: nonprod
  additional_tags:
    Status: "Suspended"
    Reason: "Project completed"
    Closure_Date: "2025-01-15"
```

**Account Removal Workflow:**
1. **Suspend in Organization**: Update YAML config → Deploy
2. **Data Backup**: Ensure all critical data is backed up
3. **Resource Cleanup**: Remove/migrate resources from account
4. **AWS Account Closure**: Follow AWS documentation for formal closure
5. **Remove from Config**: Delete from YAML after AWS closure complete

#### 3. Deploy Changes
```bash
tofu plan   # Review account placement
tofu apply  # Deploy account to correct OU
```

#### 4. Verify Deployment
- ✅ Account appears in correct OU (Organizations console)
- ✅ GuardDuty enabled automatically (audit account console)
- ✅ Control Tower guardrails applied (if in managed OU)
- ✅ SSO access provisioned (based on account_type)

### Account Lifecycle Management

| Status | Actions | Notes |
|--------|---------|-------|
| **Active** | Normal operations, monitoring, compliance | Standard state |
| **Suspended** | Investigate security issues, limit access | Temporary state |
| **Closed** | Data retention, final backups, termination | Requires approval |

## OU Management

### Adding New Organizational Units

#### 1. Update YAML Configuration
Add new OUs to the project's YAML configuration:

```yaml
# -- inputs/organizational_units.yaml --
# Standard OUs (automatically included)
# Infrastructure_Prod: { lifecycle: "prod" }
# Infrastructure_NonProd: { lifecycle: "nonprod" }
# Workloads_Prod: { lifecycle: "prod" }
# Workloads_NonProd: { lifecycle: "nonprod" }

# New custom OUs - no code changes needed!
Development:
  lifecycle: nonprod
  description: "Development and testing environments"

Research_Prod:
  lifecycle: prod
  description: "Research and development production workloads"

Sandbox_Test:
  lifecycle: nonprod
  description: "Experimental and proof-of-concept workloads"
```

#### 2. Deploy OU Structure
```bash
tofu plan   # Review new OU creation
tofu apply  # Create new OUs
```

#### 3. Move Accounts to New OUs
Update account configurations to use new OU names, then redeploy.

### OU Best Practices
- **Lifecycle Consistency**: All accounts in OU must match OU lifecycle
- **Purpose Alignment**: Group accounts by function/purpose
- **Governance**: Consider Control Tower guardrail requirements
- **Naming Convention**: Use clear, descriptive OU names


## Access Management

### SSO Operations

#### Adding New Users
1. **Identity Center**: Add user to appropriate groups
2. **Permission Sets**: Verify group has correct permissions
3. **Account Access**: Confirm access to required accounts
4. **Documentation**: Record access grants and justification

#### Managing Permission Sets
```hcl
# Example: Permission sets are defined per group/persona
locals {
  aws_sso_groups = {
    aws_admin = {
      display_name       = "${var.project}-AwsAdmin"
      description        = "Administrator access provides full access to AWS services and resources."
      managed_policy_arn = "arn:aws-us-gov:iam::aws:policy/AdministratorAccess"
    }
    aws_sec_auditor = {
      display_name       = "${var.project}-AwsSecAuditor"
      description        = "Read-only access for security audit."
      managed_policy_arn = "arn:aws-us-gov:iam::aws:policy/SecurityAudit"
    }
    # ...other groups...
  }
}
```

### Cross-Account Access Patterns
- **Security Services**: Use audit account as hub
- **Operations**: Management account for organizational tasks
- **Development**: Workload accounts for application teams
- **Audit**: Log archive account for compliance teams

## Rollback Procedures

### GitOps-Based Rollback Strategy
Rollback and recovery should be performed using GitOps principles:

1. **Identify the desired rollback point**: Locate the previous known-good commit in your version control system (e.g., Git).
2. **Revert or checkout the commit**: Use `git revert` or `git checkout <commit>` to restore the configuration and code to the desired state.
3. **Push changes to your main branch**: Commit and push the rollback to your repository. This triggers your CI/CD pipeline to redeploy the reverted configuration automatically.
4. **Monitor pipeline execution**: Ensure the pipeline completes successfully and the infrastructure matches the intended state.
5. **Verify rollback success**: Use tofu plan and monitoring tools to confirm that the rollback has restored the expected configuration and resources.

> [!IMPORTANT]
> Manual rollbacks using local tofu commands are discouraged in production. Always use version control and CI/CD automation to ensure traceability, auditability, and consistency.

## Monitoring and Alerting

### Key Metrics to Monitor

#### Infrastructure Health
- **Account Status**: All accounts healthy and compliant
- **OU Structure**: Proper account placement and organization
- **Provider Health**: Management and audit account access working

#### Security Posture
- **GuardDuty Findings**: Threat detection effectiveness
- **Compliance Score**: Control Tower and Config compliance
- **Access Patterns**: SSO usage and permission effectiveness

#### Operational Metrics
- **Deployment Success**: Terraform apply success rate
- **Change Frequency**: Configuration change velocity
- **Incident Response**: Security incident resolution time

### Alerting Configuration
```bash
# Set up CloudWatch alarms for critical metrics
aws cloudwatch put-metric-alarm \
  --alarm-name "GuardDuty-High-Severity-Findings" \
  --alarm-description "Alert on high-severity GuardDuty findings" \
  --metric-name "FindingCount" \
  --namespace "AWS/GuardDuty" \
  --statistic "Sum" \
  --threshold 1
```

## Troubleshooting

### Common Issues and Solutions

| Issue | Symptoms | Solution | Prevention |
|-------|----------|----------|------------|
| **Account placement errors** | Validation failures | Check OU/lifecycle consistency | Use validation checklist |
| **Provider authentication** | Access denied errors | Verify AWS credentials | Monitor credential expiry |
| **Control Tower drift** | Guardrail failures | Re-run Landing Zone setup | Regular compliance checks |
| **SSO permission issues** | Access denied | Review permission sets | Regular access audits |
