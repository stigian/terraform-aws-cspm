# GuardDuty Service Documentation

**Amazon GuardDuty** - Organization-wide threat detection and security monitoring.

## Overview

GuardDuty provides intelligent threat detection using machine learning, anomaly detection, and integrated threat intelligence to identify malicious activity across your AWS environment.

### Implementation Status
- ✅ **Module**: `/modules/guardduty/` 
- ✅ **Deployment**: Ready for production
- ✅ **SRA Compliance**: Fully documented and validated
- ✅ **Provider Pattern**: External provider configured

### Key Features
- **Organization-wide enablement**: Automatic coverage for all accounts
- **Delegated administration**: Audit account (261523644253) manages all findings
- **Machine learning detection**: Behavioral analysis and anomaly detection
- **Threat intelligence**: Integration with AWS and third-party threat feeds
- **Cross-account visibility**: Centralized findings in audit account

## Architecture

```
┌─── Management Account ─────────────────────────────────┐
│ • GuardDuty Organization Admin Account setup          │
│ • Enables GuardDuty across all organization accounts  │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─── Audit Account (261523644253) ───────────────────────┐
│ • Delegated Administrator for GuardDuty               │
│ • Central findings aggregation                        │
│ • Integration with Security Hub (future)              │
│ • Detective integration (future)                      │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─── All Member Accounts ────────────────────────────────┐
│ • Automatic GuardDuty enablement                      │
│ • Findings forwarded to audit account                 │
│ • No local management required                        │
└────────────────────────────────────────────────────────┘
```

## Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[SRA Compliance](./sra-compliance.md)** | AWS Security Reference Architecture alignment | Security teams |
| **[Module README](../../modules/guardduty/README.md)** | Technical implementation details | Developers |

## Configuration

### Basic Deployment
```hcl
module "guardduty" {
  source = "./modules/guardduty"
  
  audit_account_id = "261523644253"
  
  providers = {
    aws.audit = aws.audit
  }
  
  depends_on = [module.controltower]
}
```

### Key Variables
- `audit_account_id`: Account that serves as delegated administrator
- `finding_publishing_frequency`: How often findings are published (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)

## Operations

### Deployment Steps
1. **Prerequisites**: Control Tower must be deployed first
2. **Deploy**: `tofu apply -target=module.guardduty`
3. **Verify**: Check audit account for GuardDuty findings console
4. **Monitor**: Findings appear automatically for all accounts

### Monitoring & Maintenance
- **Findings Review**: Check audit account GuardDuty console daily
- **Member Account Status**: Monitor organization configuration for new accounts
- **Integration**: Prepare for Security Hub integration in next phase

### Troubleshooting
Common issues and solutions:

| Issue | Cause | Solution |
|-------|-------|----------|
| Provider errors | Missing external provider | Verify `aws.audit` provider configuration |
| Access denied | Missing permissions | Check audit account IAM permissions |
| Organization not enabled | Control Tower not deployed | Deploy Control Tower first |

## Security Considerations

### AWS SRA Alignment
- ✅ **Delegated Administrator**: Uses audit account as recommended
- ✅ **Organization-wide Coverage**: Automatic enablement for all accounts
- ✅ **Centralized Management**: Single point of control and visibility
- ✅ **Integration Ready**: Prepared for Security Hub and Detective

### Compliance Benefits
- **Continuous Monitoring**: 24/7 threat detection across all accounts
- **Automated Response**: EventBridge integration for automated workflows
- **Audit Trail**: Complete findings history for compliance reporting
- **Multi-Account Visibility**: Unified security posture view

## Future Enhancements

### Phase 2 Integrations
- 🚧 **Security Hub**: Central security findings dashboard
- 🚧 **Detective**: Deep security investigation capabilities
- 🚧 **EventBridge**: Automated response workflows
- 🚧 **SNS**: Alert notifications for critical findings

### Advanced Features
- 🚧 **Custom findings**: Export to SIEM systems
- 🚧 **Suppression rules**: Reduce false positives
- 🚧 **Malware protection**: S3 and EBS scanning
- 🚧 **Runtime monitoring**: EKS and Lambda protection

---

*Last updated: July 31, 2025*
