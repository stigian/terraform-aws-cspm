# Operations Overview

**Daily Operations Guide** - Day-to-day management and maintenance procedures for terraform-aws-cspm.

## Quick Reference

### Most Common Operations

| Task | Command/Process | Frequency | Documentation |
|------|----------------|-----------|---------------|
| **Add new account** | CLI → Terraform config → Deploy | As needed | [Account Management](#account-management) |
| **Add new OU** | Update `organizational_units` variable | As needed | [OU Management](#ou-management) |
| **Monitor security** | Review GuardDuty findings | Daily | [Security Operations](#security-operations) |
| **Check compliance** | Control Tower dashboard | Weekly | [Compliance Monitoring](#compliance-monitoring) |
| **Manage SSO access** | Identity Center console | As needed | [Access Management](#access-management) |

### Emergency Procedures
- **🚨 Security Incident**: [Incident Response](#incident-response)
- **⚠️ Service Outage**: [Troubleshooting Guides](./by_service/)
- **🔄 Deployment Failure**: [Rollback Procedures](#rollback-procedures)

## Account Management

### Adding New AWS Accounts

#### 1. Create Account via CLI (Required First)
```bash
# GovCloud (most common)
aws organizations create-gov-cloud-account \
  --account-name "YourOrg-Department-Environment" \
  --email "aws-dept@yourorg.com" \
  --profile your-management-profile

# Commercial AWS
aws organizations create-account \
  --account-name "YourOrg-Department-Environment" \
  --email "aws-dept@yourorg.com" \
  --profile your-management-profile
```

#### 2. Add to Terraform Configuration
```hcl
# In terraform.tfvars or your configuration
aws_account_parameters = {
  # Existing accounts...
  
  "NEW_ACCOUNT_ID" = {
    name         = "Exact-CLI-Name"           # Must match CLI exactly
    email        = "exact-email@domain.com"  # Must match CLI exactly
    ou           = "Workloads_Prod"          # Choose appropriate OU
    lifecycle    = "prod"                    # prod or nonprod
    account_type = "workload"                # AWS SRA account type
  }
}
```

#### 3. Deploy Changes
```bash
cd examples/
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

#### 1. Update Configuration
```hcl
# Simply extend the organizational_units variable
organizational_units = {
  # Standard OUs
  Infrastructure_Prod    = { lifecycle = "prod" }
  Infrastructure_NonProd = { lifecycle = "nonprod" }
  Workloads_Prod        = { lifecycle = "prod" }
  Workloads_NonProd     = { lifecycle = "nonprod" }
  
  # New custom OUs - no code changes needed!
  Development           = { lifecycle = "nonprod" }
  Research_Prod         = { lifecycle = "prod" }
  Sandbox_Test          = { lifecycle = "nonprod" }
}
```

#### 2. Deploy OU Structure
```bash
cd examples/
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

## Security Operations

### Daily Security Monitoring

#### GuardDuty Findings Review
1. **Access Audit Account**: Log into audit account (261523644253)
2. **Open GuardDuty Console**: Review findings dashboard
3. **Triage Findings**: Categorize by severity and impact
4. **Investigate High/Critical**: Deep dive into serious threats
5. **Document Response**: Record actions taken

#### Security Health Checks
```bash
# Check GuardDuty status across accounts
aws guardduty list-detectors --region us-east-1

# Review Control Tower compliance
aws controltower list-enabled-controls --target-identifier "OU_ID"

# Monitor SSO access patterns
aws sso-admin list-permission-sets --instance-arn "SSO_INSTANCE_ARN"
```

### Weekly Security Reviews

| Day | Task | Focus | Output |
|-----|------|-------|--------|
| **Monday** | GuardDuty findings summary | Threat landscape | Weekly report |
| **Wednesday** | Control Tower compliance | Guardrail status | Compliance dashboard |
| **Friday** | SSO access review | Permission changes | Access audit log |

### Incident Response

#### Security Incident Workflow
```
Detection → Classification → Investigation → Containment → Eradication → Recovery
     │            │               │              │              │           │
     ▼            ▼               ▼              ▼              ▼           ▼
GuardDuty → High/Med/Low → Detective → Isolate → Remediate → Monitor
```

#### Incident Classification
- **High**: Active compromise, data exfiltration, persistent threats
- **Medium**: Suspicious activity, policy violations, configuration drift  
- **Low**: Reconnaissance, false positives, informational findings

#### Response Procedures
1. **Immediate**: Document finding, assess scope, notify stakeholders
2. **Investigation**: Use Detective, CloudTrail, Config for evidence
3. **Containment**: Isolate affected resources, revoke compromised access
4. **Remediation**: Apply fixes, update policies, strengthen controls
5. **Recovery**: Restore services, monitor for recurrence
6. **Lessons Learned**: Update procedures, improve detection

## Compliance Monitoring

### Control Tower Compliance

#### Daily Checks
- **Guardrail Status**: All mandatory guardrails active
- **Account Drift**: No configuration drift from baseline
- **New Account Compliance**: Recently added accounts compliant

#### Weekly Reviews
- **Compliance Dashboard**: Review overall organizational compliance
- **Guardrail Violations**: Investigate and remediate any violations
- **Account Factory**: Review provisioned accounts and templates

#### Monthly Reports
- **Compliance Metrics**: Quantify compliance posture trends
- **Guardrail Effectiveness**: Assess guardrail impact and coverage
- **Risk Assessment**: Identify compliance gaps and risks

### Service-Specific Compliance

| Service | Check Frequency | Key Metrics | Action Items |
|---------|----------------|-------------|--------------|
| **GuardDuty** | Daily | Finding counts, false positive rate | Tune detection rules |
| **Config** | Weekly | Compliance score, rule violations | Remediate non-compliance |
| **CloudTrail** | Monthly | Log integrity, coverage gaps | Ensure complete logging |
| **SSO** | Monthly | Access patterns, unused permissions | Review and cleanup |

## Access Management

### SSO Operations

#### Adding New Users
1. **Identity Center**: Add user to appropriate groups
2. **Permission Sets**: Verify group has correct permissions
3. **Account Access**: Confirm access to required accounts
4. **Documentation**: Record access grants and justification

#### Managing Permission Sets
```hcl
# Example permission set configuration
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

#### Access Reviews
- **Monthly**: Review user access and activity
- **Quarterly**: Audit permission sets and policies
- **Annually**: Complete access certification

### Cross-Account Access Patterns
- **Security Services**: Use audit account as hub
- **Operations**: Management account for organizational tasks
- **Development**: Workload accounts for application teams
- **Audit**: Log archive account for compliance teams

## Backup and Recovery

### Configuration Backup
```bash
# Backup Terraform state
aws s3 cp terraform.tfstate s3://backup-bucket/tfstate/$(date +%Y%m%d)/

# Export Organizations structure
aws organizations list-organizational-units-for-parent --parent-id ROOT_ID > ou-backup.json

# Export SSO configuration  
aws sso-admin list-permission-sets --instance-arn INSTANCE_ARN > sso-backup.json
```

### Disaster Recovery Procedures

#### Service Recovery Priority
1. **Critical**: Organizations, Control Tower, SSO
2. **High**: GuardDuty, Config, CloudTrail
3. **Medium**: Security Hub, Detective, Inspector
4. **Low**: Custom configurations, non-essential services

#### Recovery Steps
1. **Assess Impact**: Determine scope of outage/failure
2. **Restore Core**: Organizations and Control Tower first
3. **Restore Security**: Security services and monitoring
4. **Validate**: Confirm all services operational
5. **Monitor**: Watch for issues post-recovery

## Rollback Procedures

### Safe Rollback Strategy
```bash
# 1. Review current state
tofu plan

# 2. Identify specific resources to rollback
tofu plan -target=module.specific_service

# 3. Use previous known-good configuration
git checkout KNOWN_GOOD_COMMIT

# 4. Apply rollback
tofu apply -target=module.specific_service

# 5. Verify rollback success
tofu plan  # Should show no changes
```

### Rollback Decision Matrix

| Scenario | Action | Risk Level | Approval Required |
|----------|--------|------------|-------------------|
| **Config change error** | Immediate rollback | Low | Self-service |
| **Service disruption** | Coordinated rollback | Medium | Team lead |
| **Security impact** | Emergency rollback | High | Security team |
| **Multi-service failure** | Staged rollback | Critical | Management |

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

### Diagnostic Commands
```bash
# Check Terraform state health
tofu show | grep -E "(error|fail)"

# Verify AWS service status
aws sts get-caller-identity  # Check credentials
aws organizations describe-organization  # Check org access
aws guardduty list-detectors  # Check GuardDuty

# Monitor deployment logs
tail -f terraform.log | grep -E "(ERROR|WARN)"
```

## Maintenance Schedules

### Daily Tasks (5-10 minutes)
- Review GuardDuty findings
- Check Control Tower compliance dashboard
- Monitor any ongoing deployments

### Weekly Tasks (30-45 minutes)
- Review SSO access patterns
- Update documentation as needed
- Plan upcoming account/OU changes

### Monthly Tasks (2-3 hours)
- Complete security access reviews
- Update Terraform modules
- Review and optimize configurations

### Quarterly Tasks (Half day)
- Comprehensive security audit
- Update disaster recovery procedures
- Plan major architecture changes

---

**📋 Service-Specific Operations**: [Service Documentation](./by_service/)

*Last updated: July 31, 2025*
