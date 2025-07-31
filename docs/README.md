# terraform-aws-cspm Documentation

**DoD Zero Trust CSPM (Cloud Security Posture Management)** for AWS - Complete documentation hub for administrators, operators, and security teams.

---

## 🚀 Getting Started

**New to the module?** Start here:

1. **[Main README](../README.md)** - Project overview and quick setup
2. **[Account Management Guide](./account-management-guide.md)** - Essential account creation workflows
3. **[Extending OUs and Lifecycles](./extending-ous-and-lifecycles.md)** - Customization guide

---

## 👨‍💼 For Administrators

### Initial Setup & Deployment
| Document | Purpose | Audience |
|----------|---------|----------|
| **[Account Management Guide](./account-management-guide.md)** | Account creation workflows, CLI procedures | Admins |
| **[Control Tower Integration](./control-tower-integration.md)** | Landing zone deployment, OU management | Admins |
| **[Integration Strategy](./integration-strategy.md)** | Multi-account patterns, provider setup | Admins |

### Configuration & Customization
| Document | Purpose | Audience |
|----------|---------|----------|
| **[Extending OUs and Lifecycles](./extending-ous-and-lifecycles.md)** | ⭐ Adding new OUs, custom environments | Admins |
| **[Multi-Account Provider Patterns](./MULTI_ACCOUNT_PROVIDER_PATTERNS.md)** | Advanced provider management | Admins |
| **[State Management Strategy](./state-management-strategy.md)** | Terraform state organization | Admins |

---

## 🔧 For Operations Teams

### Daily Operations & Maintenance
| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[Operations Guide](./operations-guide.md)** | 🔧 Daily tasks, maintenance procedures | Daily operations |
| **[Control Tower Troubleshooting](./control-tower-troubleshooting.md)** | ⚠️ Pre-deployment checks, error resolution | Before CT deployments |
| **Module READMEs** ([Orgs](../modules/organizations/README.md), [SSO](../modules/sso/README.md), [CT](../modules/controltower/README.md)) | Module-specific operations | Daily operations |

### Daily Operations
| Task | Documentation | Notes |
|------|---------------|-------|
| **Add new accounts** | [Operations Guide](./operations-guide.md) → Account Management | CLI-first workflow |
| **Add new OUs** | [Operations Guide](./operations-guide.md) → OU Management | No code changes needed |
| **SSO user management** | [Operations Guide](./operations-guide.md) → SSO Operations | Identity Center integration |
| **Troubleshoot CT issues** | [Control Tower Troubleshooting](./control-tower-troubleshooting.md) | Critical for re-deployments |
| **Monitor compliance** | [Operations Guide](./operations-guide.md) → Security Operations | Config/Security Hub |

---

## 🛡️ For Security Teams

### Security Architecture & Features
| Document | Purpose | Focus Area |
|----------|---------|------------|
| **[Security Features Guide](./security-features-guide.md)** | 🛡️ Complete security controls overview | Security architecture |
| **[Integration Strategy](./integration-strategy.md)** | DISA SCCA compliance patterns | Architecture |
| **[Control Tower Integration](./control-tower-integration.md)** | Guardrails and compliance | Governance |
| **[Multi-Account Provider Patterns](./MULTI_ACCOUNT_PROVIDER_PATTERNS.md)** | Cross-account security | Access patterns |

### Security Implementation
- **🔐 DISA SCCA Compliance**: Cloud-native implementation with AWS SRA fallback
- **🏛️ Zero Trust Architecture**: Cross-account security services with least privilege  
- **📊 Centralized Compliance**: Control Tower guardrails with Config/Security Hub integration
- **🔑 IAM Identity Center**: Centralized access control with role-based permissions
- **🚨 Threat Detection**: GuardDuty, Inspector, Detective for comprehensive monitoring
- **📋 Continuous Compliance**: Automated Config rules with Security Hub aggregation

---

## 📚 Reference Documentation

### Configuration Files
| File | Purpose | Location |
|------|---------|----------|
| **Account Schema** | Parameter validation rules | `config/account-schema.yaml` |
| **SRA Account Types** | Valid account type values | `config/sra-account-types.yaml` |
| **Live Configuration** | Deployment parameters | `examples/terraform.tfvars` |

### Module Documentation
| Module | Purpose | README |
|--------|---------|--------|
| **Organizations** | AWS Organizations management | [README](../modules/organizations/README.md) |
| **SSO** | IAM Identity Center integration | [README](../modules/sso/README.md) |
| **Control Tower** | Landing zone deployment | [README](../modules/controltower/README.md) |
| **YAML Transform** | Config file processing | [README](../modules/yaml-transform/README.md) |

### Examples & Templates
| Example | Purpose | Location |
|---------|---------|----------|
| **Basic Deployment** | Standard CSPM setup | `examples/` |
| **YAML Configuration** | File-driven config | `examples/advanced-yaml-config/` |
| **Live Environment** | Production patterns | `examples/terraform.tfvars` |

---

## 🔍 Quick Lookup

### Common Questions
| Question | Answer |
|----------|--------|
| **How do I add a new OU?** | [Operations Guide](./operations-guide.md) → OU Management |
| **Control Tower deployment failed?** | [Troubleshooting Guide](./control-tower-troubleshooting.md) |
| **Need to create new accounts?** | [Operations Guide](./operations-guide.md) → Account Management |
| **SSO configuration issues?** | [Operations Guide](./operations-guide.md) → SSO Operations |
| **Architecture questions?** | [Integration Strategy](./integration-strategy.md) |
| **Daily maintenance tasks?** | [Operations Guide](./operations-guide.md) |

### Emergency Procedures
| Issue | Solution | Documentation |
|-------|---------|---------------|
| **Control Tower stuck** | CLI cleanup procedures | [CT Troubleshooting](./control-tower-troubleshooting.md) |
| **Account placement errors** | Validation and placement rules | [Account Management](./account-management-guide.md) |
| **Provider authentication** | Cross-account role setup | [Provider Patterns](./MULTI_ACCOUNT_PROVIDER_PATTERNS.md) |

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    DISA SCCA Implementation                 │
├─────────────────────────────────────────────────────────────┤
│ Management Account                  │ Security OU           │
│ ├─ AWS Organizations               │ ├─ Log Archive         │
│ ├─ Control Tower                   │ ├─ Audit              │
│ ├─ IAM Identity Center             │ └─ Security            │
│ └─ Cross-account Security          │                       │
│                                    │ Infrastructure OU     │
│ Workloads OU                      │ ├─ Network            │
│ ├─ Production Accounts            │ ├─ Shared Services    │
│ ├─ Non-Production Accounts        │ └─ Deployment         │
│ └─ Sandbox Accounts               │                       │
└─────────────────────────────────────────────────────────────┘
```

**Key Principles:**
- **DISA SCCA Primary**: Cloud-native interpretation of DoD requirements
- **AWS SRA Fallback**: When SCCA documentation is insufficient
- **Zero Trust**: Least privilege with cross-account security services
- **Compliance First**: Control Tower guardrails with automated remediation

---

## 📝 Contributing to Documentation

### Documentation Standards
When adding new documentation:

1. **File Naming**: Use kebab-case (e.g., `control-tower-troubleshooting.md`)
2. **Categories**: Choose appropriate category in this index
3. **Cross-References**: Update related documents and this index
4. **Audience**: Clearly identify target audience (Admin/Ops/Security)
5. **Examples**: Include practical examples and commands

### Content Guidelines
- **Start with purpose**: What problem does this solve?
- **Include prerequisites**: What must be done first?
- **Provide examples**: Show real configuration/commands
- **Document decisions**: Explain architectural choices
- **Update timestamps**: Keep maintenance dates current

### Review Process
- Test all commands and examples
- Verify cross-references work
- Update this index when adding new docs
- Consider impact on related modules

---

## 🎯 Document Maintenance

| Document | Last Updated | Review Frequency | Owner |
|----------|--------------|------------------|--------|
| **Documentation Index** | July 2025 | Monthly | Platform Team |
| **Operations Guide** | July 2025 | Monthly | Operations Team |
| **Security Features Guide** | July 2025 | Quarterly | Security Team |
| **Control Tower Troubleshooting** | July 2025 | Before each CT deployment | Platform Team |
| **Account Management Guide** | Current | Quarterly | Operations Team |
| **Extending OUs Guide** | Current | As needed | Platform Team |
| **Integration Strategy** | Current | Semi-annually | Architecture Team |

**Next Review**: August 2025

---

*For questions, improvements, or additions to this documentation, please create an issue or pull request.*
