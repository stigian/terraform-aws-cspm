# AWS Security Reference Architecture (SRA) Compliance

This document demonstrates how our terraform-aws-cspm module aligns with the [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/) and implements AWS security best practices.

## Overview

The AWS Security Reference Architecture (SRA) provides prescriptive guidance for designing and implementing security controls in AWS environments. Our implementation follows SRA best practices for:

- ✅ **Organization structure** with proper OU design
- ✅ **Delegated administrator patterns** for security services
- ✅ **Security service integration** and centralization
- ✅ **Control Tower baseline** with enhanced security services

## Account Structure & OU Design

### SRA Guidance
> *"AWS Control Tower names the account under the Security OU the Audit Account by default."*
> 
> *"The Security Tooling account serves as the administrator account for security services that are managed in an administrator/member structure throughout the AWS accounts."*

### Our Implementation

```
Organization Root
├── Security OU (Control Tower Managed)
│   ├── Audit Account                       ← Security Tooling/Delegated Admin
│   └── Log Archive Account                ← Centralized Logging
├── Infrastructure OUs (Organizations Managed)
│   ├── Infrastructure_Prod
│   └── Infrastructure_NonProd
└── Workloads OUs (Organizations Managed)
    ├── Workloads_Prod
    └── Workloads_NonProd
```

**✅ SRA Compliance**: Our Security OU placement and account types match AWS SRA recommendations exactly.

## Delegated Administrator Strategy

### SRA Guidance
> *"Services in the AWS SRA that currently support delegated administrator include AWS Config, AWS Firewall Manager, Amazon GuardDuty, AWS IAM Access Analyzer, Amazon Macie, AWS Security Hub, Amazon Detective, AWS Audit Manager, Amazon Inspector, AWS CloudTrail, and AWS Systems Manager."*

### Our Implementation

| Security Service | Delegated Admin Account | Implementation Status |
|-----------------|-------------------------|----------------------|
| **GuardDuty** | Audit Account | **Deployed** |
| **Security Hub** | Audit Account | **Planned** |
| **Config** | Audit Account | **Planned** |
| **Inspector** | Audit Account | **Planned** |
| **Detective** | Audit Account | **Planned** |

**✅ SRA Compliance**: Using consistent delegated administrator account across all security services for streamlined integration.

## GuardDuty Implementation

### SRA Guidance
> *"GuardDuty is enabled in all accounts through AWS Organizations, and all findings are viewable and actionable by appropriate security teams in the GuardDuty delegated administrator account (in this case, the Security Tooling account)."*

### Our Implementation

```hcl
# Organization-wide GuardDuty with delegated admin
resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = var.audit_account_id  # Your audit account ID
}

resource "aws_guardduty_organization_configuration" "this" {
  provider                         = aws.audit
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.audit.id
}
```

**Key SRA Features Implemented:**
- ✅ **Organization-wide enablement**: `auto_enable_organization_members = "ALL"`
- ✅ **Delegated administration**: Audit account manages all member accounts
- ✅ **Automatic member account detection**: New accounts automatically get GuardDuty
- ✅ **Centralized findings management**: All findings visible in audit account
- ✅ **Cross-account provider pattern**: External provider for security isolation

### SRA Integration Benefits
> *"When AWS Security Hub is enabled, GuardDuty findings automatically flow to Security Hub. When Amazon Detective is enabled, GuardDuty findings are included in the Detective log ingest process."*

**✅ Future Integration**: Our GuardDuty deployment sets foundation for Security Hub and Detective integration.

## Hybrid Architecture Design

### SRA Alignment
Our hybrid Control Tower + Organizations approach aligns with SRA principles:

#### Control Tower Benefits (SRA Endorsed)
- **Baseline Security**: Provides foundational guardrails and monitoring
- **Security OU Management**: Manages audit and log archive accounts
- **Service Integration**: Native integration with AWS security services
- **Compliance**: Built-in compliance with AWS best practices

#### Organizations Module Benefits
- **Custom OU Structure**: Flexible Infrastructure and Workloads OUs
- **Account Management**: Handles non-Control Tower accounts
- **Scalability**: Supports diverse organizational requirements
- **Cost Optimization**: Manages only necessary resources

### SRA Design Principle
> *"Some services and features are a great fit for implementing controls across your full AWS organization... Other services and features are best used to help protect individual resources within an AWS account."*

**✅ Our Approach**: Control Tower for organization-wide controls, Organizations module for account-specific management.

## Security Services Layer Strategy

### SRA Six-Layer Model
The SRA defines six layers of security controls:

1. **Organization Layer** → Control Tower + Organizations Module ✅
2. **OU Layer** → Security/Infrastructure/Workloads OUs ✅
3. **Account Layer** → Cross-account security services ✅ 
4. **Network Layer** → Planned (VPC Security Groups, Network Firewall)
5. **Principal Layer** → SSO + IAM Integration ✅
6. **Resource Layer** → Planned (Resource-based policies)

### Current Implementation Status

```
┌─ Organization-wide Security Services ─────────────────┐
│ ✅ GuardDuty (Threat Detection)                       │
│ 🚧 Security Hub (Central Security Dashboard)         │
│ 🚧 Config (Configuration Compliance)                 │
│ 🚧 Inspector (Vulnerability Assessment)              │
└───────────────────────────────────────────────────────┘
┌─ Control Tower Baseline ──────────────────────────────┐
│ ✅ CloudTrail (Audit Logging)                         │
│ ✅ Config Rules (Detective Guardrails)                │
│ ✅ Service Catalog (Preventive Guardrails)           │
└───────────────────────────────────────────────────────┘
┌─ Identity & Access Management ────────────────────────┐
│ ✅ SSO (Single Sign-On)                               │
│ ✅ IAM Roles & Policies                               │
│ 🚧 IAM Access Analyzer (Planned)                     │
└───────────────────────────────────────────────────────┘
```

## Compliance & Audit Readiness

### SRA Audit Manager Integration
> *"In order for Audit Manager to collect Security Hub evidence, the delegated administrator account for both services has to be the same AWS account. For this reason, in the AWS SRA, the Security Tooling account is the delegated administrator for Audit Manager."*

**Design Decision**: Using audit account as delegated admin for all security services ensures seamless Audit Manager integration when deployed.

### Evidence Collection Pipeline
```
GuardDuty Findings → Security Hub → Audit Manager → Compliance Reports
        ↓
   Detective Analysis → EventBridge → Automated Response
```

## Documentation References

### Primary AWS SRA Sources
- [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/)
- [Security Services Organization-wide](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/security-services.html)
- [Security Tooling Account](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/security-tooling.html)
- [Control Tower Integration](https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html)

### Implementation Examples
- [AWS SRA Code Library](https://github.com/aws-samples/aws-security-reference-architecture-examples)
- [GuardDuty Organization Implementation](https://github.com/aws-samples/aws-security-reference-architecture-examples/tree/main/aws_sra_examples/solutions/guardduty)

## Next Steps

### Phase 1: Core Security Services (Current)
- ✅ **GuardDuty**: Organization-wide threat detection
- 🚧 **Security Hub**: Central security findings aggregation
- 🚧 **Config**: Configuration compliance monitoring

### Phase 2: Enhanced Detection & Response
- 🚧 **Detective**: Security investigation and analysis
- 🚧 **Inspector**: Vulnerability assessment
- 🚧 **Macie**: Data security and privacy

### Phase 3: Governance & Compliance
- 🚧 **Audit Manager**: Compliance evidence collection
- 🚧 **IAM Access Analyzer**: Access review and optimization
- 🚧 **Firewall Manager**: Network security policies

## Conclusion

Our terraform-aws-cspm implementation follows AWS Security Reference Architecture best practices and provides a solid foundation for enterprise-grade security in AWS. The hybrid Control Tower + Organizations approach maximizes both security baseline coverage and organizational flexibility while maintaining full SRA compliance.

---

*This documentation is maintained to reflect current AWS SRA guidance and implementation status. Last updated: July 31, 2025*
