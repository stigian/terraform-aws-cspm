# terraform-aws-cspm Documentation

**DoD Zero Trust CSPM (Cloud Security Posture Management)** for AWS - Complete documentation organized by role and technical implementation.

---

## Getting Started

**New to the module?** Start with your role:

1. **[Administrator Guide](./by_persona/administrator.md)** - Complete setup, deployment, and configuration guide
2. **[Operations Guide](./by_persona/operations.md)** - Daily operations, monitoring, and maintenance procedures  
3. **[Security Team Guide](./by_persona/security-team.md)** - Security architecture, monitoring, and incident response
4. **[AWS SRA Compliance](./architecture/aws-sra-compliance.md)** - AWS Security Reference Architecture alignment

---

## Documentation by Role

### Administrators
**[Complete Administrator Guide](./by_persona/administrator.md)**

Everything administrators need to deploy and manage the infrastructure:
- CLI-First Account Creation - Required workflow and validation
- Deployment Sequence - Step-by-step foundation deployment
- Configuration Management - Variables, validation, and best practices
- Provider Configuration - Multi-account access patterns
- Architecture Understanding - Hybrid Control Tower + Organizations design
- Troubleshooting - Common issues and diagnostic procedures

### Operations Teams  
**[Complete Operations Guide](./by_persona/operations.md)**

Daily operations and maintenance procedures:
- Account Management - Adding accounts and OUs, lifecycle management
- Security Operations - Daily monitoring, incident response, compliance checks
- Access Management - SSO operations, cross-account access, user management
- Infrastructure Operations - Service health, monitoring, emergency procedures
- Maintenance Schedules - Daily, weekly, monthly, and quarterly tasks

### Security Teams
**[Complete Security Guide](./by_persona/security-team.md)**

Security architecture and monitoring procedures:
- Security Architecture - DoD Zero Trust CSPM, AWS SRA compliance, service architecture
- Security Operations - Daily monitoring, threat analysis, compliance reporting
- Incident Response - Classification, workflows, investigation tools, evidence collection
- Compliance & Auditing - DISA SCCA, AWS SRA, security controls validation
- Security Configuration - Baseline configurations, monitoring, and alerting

---

## Technical Implementation

### Module Documentation
Each service module contains detailed technical implementation documentation:

| Module | Status | Technical Documentation |
|--------|--------|------------------------|
| **[Organizations](../modules/organizations/)** | Production | Account management, OU structure, validation |
| **[Control Tower](../modules/controltower/)** | Production | Landing zone, guardrails, troubleshooting |
| **[SSO](../modules/sso/)** | Production | Identity management, permission sets, cross-account access |
| **[GuardDuty](../modules/guardduty/)** | Production | Threat detection, provider patterns, organization configuration |
| **[Security Hub](../modules/securityhub/)** | Planned | Central dashboard, compliance standards, integration |
| **[Detective](../modules/detective/)** | Planned | Investigation tools, behavioral analysis, evidence collection |
| **[Inspector](../modules/inspector2/)** | Planned | Vulnerability assessment, continuous monitoring |
| **[Config](../modules/awsconfig/)** | Planned | Configuration compliance, drift detection, remediation |

### Architecture References
- **[Integration Strategy](./architecture/integration-strategy.md)** - Control Tower integration patterns and flexibility
- **[Multi-Account Provider Patterns](./architecture/MULTI_ACCOUNT_PROVIDER_PATTERNS.md)** - Advanced provider management
- **[Extending OUs and Lifecycles](./architecture/extending-ous-and-lifecycles.md)** - Customization and extension patterns
- **[State Management Strategy](./architecture/state-management-strategy.md)** - Terraform state organization for multi-module deployments
- **[Account Management Guide](./architecture/account-management-guide.md)** - YAML configuration patterns and CLI workflows

---

## Reference Documentation

### AWS Best Practices
- **[AWS SRA Compliance](./architecture/aws-sra-compliance.md)** - Complete AWS Security Reference Architecture alignment

### Configuration Reference
| File | Purpose | Location |
|------|---------|----------|
| **Account Schema** | Parameter validation rules | `config/account-schema.yaml` |
| **SRA Account Types** | Valid account type values | `config/sra-account-types.yaml` |
| **Live Configuration** | Deployment parameters | `examples/terraform.tfvars` |

---

## Quick Navigation

### By Task
- **Deploy infrastructure**: [Administrator Guide](./by_persona/administrator.md#initial-deployment)
- **Add new account**: [Operations Guide](./by_persona/operations.md#account-management)
- **Monitor security**: [Security Guide](./by_persona/security-team.md#security-operations)
- **Troubleshoot issues**: Role-specific troubleshooting in each persona guide

### By Service
- **GuardDuty operations**: [Module docs](../modules/guardduty/docs/) + [Security monitoring](./by_persona/security-team.md#security-operations)
- **Control Tower issues**: [Module docs](../modules/controltower/docs/) + [Emergency procedures](./by_persona/operations.md#emergency-procedures)
- **SSO management**: [Module docs](../modules/sso/docs/) + [Access management](./by_persona/operations.md#access-management)

### By Architecture
- **Account structure**: [AWS SRA Compliance](./architecture/aws-sra-compliance.md#account-structure--ou-design)
- **Security services**: [Security Guide](./by_persona/security-team.md#security-service-architecture)
- **Hybrid design**: [Administrator Guide](./by_persona/administrator.md#architecture-understanding)

---

**Tip**: Start with your role-specific guide, then dive into technical module documentation as needed.

*Last updated: July 31, 2025*
