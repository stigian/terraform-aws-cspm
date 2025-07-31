# GuardDuty Implementation - AWS SRA Compliant

This document details our GuardDuty implementation following AWS Security Reference Architecture (SRA) best practices.

## Overview

Amazon GuardDuty provides organization-wide threat detection using machine learning and behavior analysis across CloudTrail events, VPC Flow Logs, and DNS logs. Our implementation follows AWS SRA patterns for maximum security coverage and operational efficiency.

## SRA Compliance

### Architecture Alignment

Our GuardDuty deployment aligns with AWS SRA guidance:

> **AWS SRA Quote**: *"GuardDuty is enabled in all accounts through AWS Organizations, and all findings are viewable and actionable by appropriate security teams in the GuardDuty delegated administrator account (in this case, the Security Tooling account)."*

#### Security Tooling Account (Audit Account)
- **Account ID**: `261523644253`
- **Location**: Security OU (Control Tower managed)
- **Role**: Delegated administrator for all security services
- **SRA Compliance**: ✅ Matches AWS SRA recommendation exactly

### Implementation Details

```hcl
# Organization-wide GuardDuty with SRA-compliant delegation
module "guardduty" {
  source = "../modules/guardduty"

  audit_account_id = module.yaml_transform.audit_account_id  # 261523644253
  global_tags      = module.yaml_transform.global_tags

  providers = {
    aws.audit = aws.audit  # Cross-account provider for security isolation
  }

  depends_on = [module.controltower]  # Wait for baseline security
}
```

## Key Features

### 1. Delegated Administrator Pattern

**SRA Benefit**: Centralized security management without granting management account access

```hcl
resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = var.audit_account_id  # Security Tooling Account
}
```

**✅ SRA Compliance**: Uses audit account (Security Tooling) as delegated administrator

### 2. Organization-wide Enablement

**SRA Benefit**: Automatic threat detection across all accounts, including future ones

```hcl
resource "aws_guardduty_organization_configuration" "this" {
  provider                         = aws.audit
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.audit.id
}
```

**✅ SRA Compliance**: `auto_enable_organization_members = "ALL"` ensures complete coverage

### 3. External Provider Pattern

**Security Benefit**: Isolates security operations from management account

```hcl
providers = {
  aws.audit = aws.audit  # Assumes role in audit account
}
```

**✅ Best Practice**: Cross-account provider prevents privilege escalation

## Security Benefits

### Threat Detection Coverage

| Data Source | Description | Coverage |
|-------------|-------------|----------|
| **CloudTrail** | API call monitoring | All accounts, all regions |
| **VPC Flow Logs** | Network traffic analysis | All VPCs organization-wide |
| **DNS Logs** | Domain resolution monitoring | All accounts automatically |

### Automatic Member Management

```
Organization
├── Management Account → GuardDuty detector (automatic)
├── Audit Account → GuardDuty admin + detector
├── Log Archive Account → GuardDuty detector (automatic)
└── Workload Accounts → GuardDuty detectors (automatic)
```

**SRA Advantage**: New accounts automatically get GuardDuty without manual configuration

## Integration Architecture

### Security Hub Integration (Planned)

> **AWS SRA Quote**: *"When AWS Security Hub is enabled, GuardDuty findings automatically flow to Security Hub."*

```
GuardDuty Findings → Security Hub → EventBridge → Automated Response
                 ↓
            Detective Analysis
```

### Detective Integration (Planned)

> **AWS SRA Quote**: *"When Amazon Detective is enabled, GuardDuty findings are included in the Detective log ingest process."*

```
GuardDuty → Detective Behavior Graph → Investigation Workflows
```

## Operational Model

### Centralized Management

**Security Team Workflow**:
1. **Monitor**: All findings in audit account GuardDuty console
2. **Investigate**: Use Detective for root cause analysis (when deployed)
3. **Respond**: Automated responses via EventBridge rules
4. **Report**: Aggregate findings in Security Hub dashboard

### Decentralized Visibility

**Account Teams**:
- Can view findings for their specific account
- Cannot modify organization-wide settings
- Focus on application-specific remediation

## Future Enhancements

### Phase 1: Enhanced Detection
- **Malware Protection**: EBS volume scanning for malware
- **S3 Protection**: Object-level threat detection
- **EKS Protection**: Kubernetes audit log monitoring

### Phase 2: Response Automation
- **EventBridge Rules**: Automatic response to high-severity findings
- **Lambda Functions**: Custom remediation workflows
- **SNS Notifications**: Real-time alerts to security teams

### Phase 3: Advanced Analytics
- **Detective Integration**: Behavior graph analysis
- **Custom Threat Intelligence**: Integration with external feeds
- **Machine Learning**: Custom models for organization-specific threats

## Compliance & Audit

### Evidence Collection

GuardDuty provides audit evidence for:
- **NIST Cybersecurity Framework**: Continuous monitoring (DE.CM)
- **ISO 27001**: Information security incident management
- **SOC 2**: Security monitoring and logging
- **FedRAMP**: Continuous security monitoring

### Retention & Access

- **Findings Retention**: Configurable retention period
- **Cross-Account Access**: Audit account has full organization visibility
- **API Access**: Programmatic access for SIEM integration
- **Compliance Reporting**: Automated compliance status reports

## Cost Optimization

### Intelligent Tiering

GuardDuty automatically optimizes costs through:
- **Free Tier**: First 30 days free for new accounts
- **Usage-Based Pricing**: Pay only for analyzed data
- **Efficient Processing**: Machine learning reduces false positives
- **Smart Sampling**: Intelligent sampling for large datasets

### Budget Monitoring

Monitor GuardDuty costs across all accounts:
```bash
# Check GuardDuty usage across organization
aws guardduty get-usage-statistics \
  --detector-id <detector-id> \
  --usage-statistic-type SUM_BY_ACCOUNT
```

## Troubleshooting

### Common Issues

1. **Detector Not Found**
   - Verify audit account has assumed role permissions
   - Check provider configuration in module call

2. **Organization Admin Not Set**
   - Ensure management account has delegated administrator permissions
   - Verify audit account is in Security OU

3. **Members Not Auto-Enrolled**
   - Check `auto_enable_organization_members = "ALL"` setting
   - Verify organization integration is enabled

### Validation Commands

```bash
# Verify delegated administrator
aws organizations list-delegated-administrators \
  --service-principal guardduty.amazonaws.com

# Check organization configuration
aws guardduty describe-organization-configuration \
  --detector-id <detector-id>

# List member accounts
aws guardduty list-members \
  --detector-id <detector-id>
```

## References

- [AWS SRA - Security Tooling Account](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/security-tooling.html)
- [GuardDuty SRA Implementation](https://github.com/aws-samples/aws-security-reference-architecture-examples/tree/main/aws_sra_examples/solutions/guardduty)
- [GuardDuty Best Practices](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_best-practices.html)
- [AWS Organizations Integration](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_organizations.html)

---

*This documentation reflects current AWS SRA guidance and implementation status. Last updated: July 31, 2025*
