# Security Team Guide

**Security architecture, monitoring, and incident response** for terraform-aws-cspm modular DISA SCCA implementation.

## Security Architecture Overview

The terraform-aws-cspm project implements **DISA SCCA-compliant security services** across AWS multi-account environments using a **centralized audit account** as the security operations hub.

### Core Security Principles

- 🛡️ **Defense in Depth**: Multiple security layers with centralized monitoring
- � **Continuous Monitoring**: Real-time threat detection and configuration compliance
- 🤖 **Automated Response**: EventBridge-driven security workflows and notifications
- � **Centralized Visibility**: All security findings aggregated in audit account
- 📋 **DISA SCCA Compliance**: Virtual Data Center Security Stack (VDSS) requirements

## Implemented Security Services

### ✅ **Production Security Services**

| Service | Module | Purpose | DISA SCCA Alignment |
|---------|--------|---------|-------------------|
| **AWS GuardDuty** | guardduty | Threat detection & monitoring | VDSS requirement 2.1.2.6 |
| **AWS Detective** | detective | Security investigation & analysis | Enhanced incident response |
| **AWS Security Hub** | securityhub | Centralized security findings | VDSS monitoring consolidation |
| **AWS Config** | awsconfig | Configuration compliance & drift | VDSS compliance monitoring |
| **AWS Control Tower** | controltower | Governance baseline & guardrails | Foundational security controls |
| **IAM Identity Center** | sso | Centralized identity & access | Zero trust access control |

### 🚧 **Planned Enhancements**
- **AWS Inspector v2**: Container and EC2 vulnerability assessment
- **Enhanced logging**: Centralized logging module (currently handled by Control Tower)
- **Security automation**: Custom response workflows
## Centralized Security Architecture

All security services use the **audit account as delegated administrator**, creating a unified security operations center:

```
┌─── Audit Account (Security Operations Hub) ────────────┐
│                                                        │
│ ┌─── Threat Detection ──────────────────────────────┐  │
│ │ • GuardDuty Organization Admin                    │  │
│ │ • Detective Behavior Graph                        │  │
│ │ • Real-time threat intelligence                   │  │
│ └───────────────────────────────────────────────────┘  │
│                                                        │
│ ┌─── Compliance Monitoring ─────────────────────────┐  │
│ │ • Security Hub Central Configuration              │  │
│ │ • Config Organization Admin                       │  │
│ │ • Compliance dashboard and reporting              │  │
│ └───────────────────────────────────────────────────┘  │
│                                                        │
│ ┌─── Cross-Account Automation ──────────────────────┐  │
│ │ • Automatic member account enrollment             │  │
│ │ • Centralized finding aggregation                 │  │
│ │ • EventBridge security workflows                  │  │
│ └───────────────────────────────────────────────────┘  │
│                                                        │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
       ┌─── All Organization Member Accounts ───┐
       │ • Auto-enabled security services       │
       │ • Findings forwarded to audit account  │
       │ • Centralized compliance monitoring    │
       └─────────────────────────────────────────┘
```

## Daily Security Operations

### GuardDuty Threat Monitoring

**Login to Audit Account** → GuardDuty console

#### Daily Tasks
1. **Review Findings**: Check for HIGH/MEDIUM severity findings
2. **Investigate Anomalies**: Use Detective for detailed investigation  
3. **Tune Protection Plans**: Adjust based on finding patterns
4. **Update Suppression Rules**: Reduce false positives

#### Protection Plan Status
Current implementation enables priority protection plans:

| Protection Plan | Status | Purpose | Cost Impact |
|----------------|--------|---------|-------------|
| **S3 Protection** | ✅ Enabled | Monitor S3 data events for exfiltration | Low |
| **Runtime Monitoring** | ✅ Enabled | eBPF-based EC2/EKS monitoring | Medium |
| **Malware Protection (EC2)** | 🔧 Optional | EBS volume scanning | High |
| **Lambda Protection** | 🔧 Optional | VPC Flow Log monitoring | Low |
| **EKS Protection** | 🔧 Optional | Kubernetes audit log monitoring | Medium |
| **RDS Protection** | 🔧 Optional | Aurora login activity monitoring | Low |

#### Common Finding Types
- **CryptoCurrency:EC2/BitcoinTool.B**: EC2 cryptocurrency mining
- **Backdoor:EC2/C&CActivity.B**: Command and control communication
- **Recon:EC2/PortProbeUnprotectedPort**: Port scanning activity
- **Trojan:EC2/BlackholeTraffic**: Malware communication attempts

### Security Hub Compliance Dashboard

**Login to Audit Account** → Security Hub console

#### Weekly Compliance Review
1. **Security Standards**: Monitor AWS Foundational Security Standard
2. **Custom Insights**: Review critical/high findings by severity
3. **Compliance Score**: Track organization-wide security posture
4. **Finding Trends**: Identify recurring security issues

#### Current Configuration
- **Central Configuration**: Organization-wide policy management
- **Auto-Enable Standards**: Disabled (manual control for cost optimization)
- **Configuration Policy**: "cnscca-baseline" with DISA SCCA controls
- **Finding Aggregation**: All accounts → audit account

### Detective Investigation Workflows

**Login to Audit Account** → Detective console

#### Incident Response Process
1. **Finding Correlation**: Link GuardDuty findings with Detective graphs
2. **Timeline Analysis**: Review 30-day activity patterns
3. **Entity Investigation**: Analyze affected resources and relationships
4. **Evidence Collection**: Export investigation data for reporting

#### Investigation Capabilities
- **Behavior Graphs**: ML-powered security analytics
- **Cross-Service Data**: CloudTrail, GuardDuty, Security Hub integration
- **Relationship Mapping**: Resource and identity relationships
- **Historical Analysis**: 30-day data retention for investigations

### Config Compliance Monitoring

**Login to Audit Account** → Config console

#### Configuration Drift Detection
1. **Compliance Dashboard**: Monitor organization-wide rule compliance
2. **Non-Compliant Resources**: Investigate configuration violations
3. **Change Timeline**: Track configuration changes across accounts
4. **Remediation**: Coordinate fixes with account owners

#### Key Compliance Rules
- **Control Tower Guardrails**: Mandatory baseline controls
- **Security Group Rules**: Network access controls
- **IAM Compliance**: Role and policy configurations
- **Encryption Standards**: Data protection requirements

## Security Service Configuration

### GuardDuty Advanced Configuration

#### Protection Plan Tuning
```bash
# Example: Enable additional protection plans
# (Configure via guardduty module variables)
enable_malware_protection_ec2 = true
enable_lambda_protection      = true
enable_eks_protection         = true
```

#### Threat Intelligence
- **Threat Intel Sets**: Custom IOC lists for enhanced detection
- **IP Sets**: Trusted/malicious IP address lists
- **Suppression Rules**: Reduce false positives for known-good activity

### Security Hub Customization

#### Custom Insights
Create focused views for your environment:
- **Critical Infrastructure**: Findings from management/network accounts
- **High-Value Targets**: Findings from production workload accounts
- **Compliance Issues**: Configuration violations and policy breaches

#### Finding Filters
Reduce noise by filtering:
- **Severity Levels**: Focus on HIGH/CRITICAL findings
- **Resource Types**: Filter by EC2, S3, IAM, etc.
- **Compliance Standards**: AWS Foundational, CIS, PCI DSS

### Detective Behavior Graph Optimization

#### Data Sources
Ensure all relevant data flows to Detective:
- **GuardDuty Findings**: Automatic integration
- **CloudTrail Events**: API activity monitoring
- **VPC Flow Logs**: Network traffic analysis
- **Security Hub Findings**: Cross-service correlation

## Incident Response Procedures

### Security Finding Triage

#### Priority 1: Critical/High Severity
1. **Immediate Assessment**: Review finding details in GuardDuty/Security Hub
2. **Detective Investigation**: Analyze using behavior graphs
3. **Containment**: Isolate affected resources if necessary
4. **Notification**: Alert stakeholders via established communication channels
5. **Documentation**: Record all investigation steps and findings

#### Priority 2: Medium Severity
1. **Daily Review**: Include in regular security operations review
2. **Pattern Analysis**: Look for trends or repeated issues
3. **Remediation Planning**: Schedule fixes with account owners
4. **Follow-up**: Verify remediation within agreed timeframes

#### Priority 3: Low/Informational
1. **Weekly Review**: Include in compliance reporting
2. **Baseline Updates**: Adjust detection rules if needed
3. **Documentation**: Update security runbooks with new patterns

### Forensic Investigation Workflow

1. **Preserve Evidence**: Snapshot affected resources
2. **Timeline Construction**: Use Detective to build activity timeline
3. **Root Cause Analysis**: Identify initial compromise vector
4. **Impact Assessment**: Determine scope of affected systems
5. **Recovery Planning**: Coordinate with operations teams
6. **Lessons Learned**: Update security controls and procedures

## Performance and Cost Optimization

### GuardDuty Cost Management

#### Protection Plan Selection
- **Start Conservative**: Enable S3 and Runtime monitoring first
- **Monitor Costs**: Use AWS Cost Explorer to track GuardDuty spend
- **Gradual Expansion**: Add additional protection plans based on findings

#### Data Volume Optimization
- **VPC Flow Logs**: Configure sampling for cost control
- **CloudTrail**: Use data events selectively for high-value buckets

### Security Hub Cost Control

#### Standards Management
- **Selective Standards**: Enable only required compliance frameworks
- **Custom Controls**: Disable unnecessary controls to reduce costs
- **Finding Retention**: Configure appropriate retention periods

### Detective Cost Considerations

#### Data Ingestion Management
- **Automatic Scaling**: Detective scales with organization size
- **30-Day Retention**: Fixed retention period balances cost and utility
- **Cross-Account Benefits**: Centralized investigation reduces per-account costs

## Compliance Reporting

### DISA SCCA Compliance Mapping

| SCCA Requirement | Implementation | Monitoring |
|------------------|----------------|------------|
| 2.1.2.6 - VDSS Monitoring | GuardDuty threat detection | Audit account dashboard |
| 2.1.2.11 - Security Information Capture | CloudTrail + Config | Control Tower baseline |
| 2.1.2.12 - Centralized Archival | Log Archive account | Control Tower logging |

### Automated Compliance Reporting

#### Security Hub Insights
- **Weekly Reports**: Automated compliance posture summaries
- **Trend Analysis**: Month-over-month security improvements
- **Exception Reporting**: Non-compliant resources requiring attention

#### Config Compliance Dashboards
- **Rule Compliance**: Organization-wide configuration compliance
- **Change Tracking**: Configuration drift detection and reporting
- **Remediation Tracking**: Fix verification and status updates

## Security Team Access Patterns

### Audit Account Access
**Primary security operations hub** with following access patterns:

```bash
# SSO Access (Recommended)
# Navigate to IAM Identity Center portal
# Select audit account
# Choose aws-cyber-sec-eng or aws-sec-auditor role

# Cross-Account CLI Access  
aws sts assume-role 
  --role-arn "arn:aws:iam::AUDIT-ACCOUNT-ID:role/AWSControlTowerExecution" 
  --role-session-name "security-operations"
```

### Permission Set Mapping

| Security Role | Permission Set | Purpose | Typical Users |
|---------------|----------------|---------|---------------|
| **Security Administrator** | aws-cyber-sec-eng | Full security service management | Security team leads |
| **Security Analyst** | aws-sec-auditor | Read-only security monitoring | SOC analysts |
| **Incident Responder** | aws-cyber-sec-eng | Investigation and response | CERT team members |

### Multi-Account Security Operations

For investigating findings across multiple accounts:

1. **Start in Audit Account**: Review centralized findings
2. **Cross-Account Investigation**: Use IAM Identity Center for account access
3. **Evidence Collection**: Gather data from affected accounts
4. **Centralized Documentation**: Record findings in audit account
## Module Integration for Security Teams

### Working with Individual Modules

Each security service is implemented as a separate module with specific operational characteristics:

| Module | Security Team Usage | Operational Notes |
|--------|-------------------|-------------------|
| **guardduty** | Primary threat detection platform | Daily monitoring, tune protection plans |
| **detective** | Investigation and forensics | Use for incident response and analysis |
| **securityhub** | Central security dashboard | Weekly compliance reviews |
| **awsconfig** | Configuration compliance | Monitor drift, track remediation |
| **controltower** | Governance foundation | Monitor guardrails, handle violations |
| **sso** | Access control management | Review permissions, manage groups |

### Cross-Module Security Workflows

#### Threat Detection → Investigation → Response
1. **GuardDuty Detection**: Initial threat identification
2. **Detective Analysis**: Deep investigation using behavior graphs
3. **Security Hub Correlation**: Link findings across services
4. **Config Validation**: Verify configuration compliance
5. **Response Actions**: Coordinate with operations teams

#### Daily Security Operations Checklist
- [ ] Review GuardDuty HIGH/CRITICAL findings (audit account)
- [ ] Check Detective behavior graphs for anomalies
- [ ] Monitor Security Hub compliance scores
- [ ] Verify Config compliance rules are passing
- [ ] Review SSO access patterns for anomalies

---

This security architecture provides comprehensive DISA SCCA-compliant monitoring and response capabilities across your AWS multi-account environment. All security services are centrally managed through the audit account, providing unified visibility and control while maintaining the flexibility to customize protection levels for different account types and workloads.
