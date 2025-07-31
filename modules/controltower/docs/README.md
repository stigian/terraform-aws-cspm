# Control Tower Service Documentation

**AWS Control Tower** - Landing zone management and organizational guardrails.

## Overview

Control Tower provides governance, compliance, and account management for multi-account AWS environments with built-in security guardrails and centralized logging.

### Implementation Status
- ✅ **Module**: `/modules/controltower/`
- ✅ **Deployment**: Production ready
- ✅ **Landing Zone**: Version 3.3 deployed
- ✅ **Hybrid Architecture**: Manages Security/Sandbox OUs

### Key Features
- **Landing Zone**: Automated multi-account environment setup
- **Guardrails**: Preventive and detective security controls
- **Account Factory**: Streamlined account provisioning
- **Service Catalog**: Standardized account templates
- **Centralized Logging**: CloudTrail and Config integration

## Architecture

```
┌─── Control Tower Landing Zone ─────────────────────────┐
│                                                        │
│ ┌─── Security OU ───────────────────────────────────┐  │
│ │ • Audit Account (261523644253)                   │  │
│ │ • Log Archive Account (261503748007)             │  │
│ │ • Delegated administrator accounts               │  │
│ └───────────────────────────────────────────────────┘  │
│                                                        │
│ ┌─── Sandbox OU ────────────────────────────────────┐  │
│ │ • Development and testing accounts               │  │
│ │ • Relaxed guardrails for experimentation         │  │
│ └───────────────────────────────────────────────────┘  │
│                                                        │
└────────────────────────────────────────────────────────┘
                           │
                           ▼ (Hybrid Integration)
┌─── Organizations Module ───────────────────────────────┐
│ ┌─── Infrastructure OUs ───────────────────────────┐   │
│ │ • Infrastructure_Prod                           │   │
│ │ • Infrastructure_NonProd                        │   │
│ └─────────────────────────────────────────────────┘   │
│                                                       │
│ ┌─── Workloads OUs ────────────────────────────────┐   │
│ │ • Workloads_Prod                                │   │
│ │ • Workloads_NonProd                             │   │
│ └─────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────┘
```

## Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[Integration Guide](./integration.md)** | Control Tower deployment and configuration | Administrators |
| **[Troubleshooting Guide](./troubleshooting.md)** | Common issues and solutions | Operations teams |
| **[Module README](../../modules/controltower/README.md)** | Technical implementation details | Developers |

## Configuration

### Basic Deployment
```hcl
module "controltower" {
  source = "./modules/controltower"
  
  # Security OU configuration
  security_ou_accounts = {
    "261523644253" = {
      name  = "CNSCCA-Security-Audit"
      email = "aws-audit@example.com"
    }
    "261503748007" = {
      name  = "CNSCCA-Security-LogArchive" 
      email = "aws-logs@example.com"
    }
  }
  
  # Additional OUs managed by Control Tower
  sandbox_ou_enabled = true
}
```

### Key Variables
- `security_ou_accounts`: Audit and log archive account configurations
- `sandbox_ou_enabled`: Enable sandbox OU for development
- `governance_at_scale_features`: Enhanced governance features
- `baseline_config`: Baseline security configuration

## Operations

### Deployment Process
1. **Prerequisites**: 
   - Accounts created via CLI first
   - Management account access configured
   - Required IAM permissions in place

2. **Deploy Landing Zone**:
   ```bash
   tofu apply -target=module.controltower
   ```

3. **Verify Deployment**:
   - Check Control Tower dashboard
   - Verify Security and Sandbox OUs
   - Confirm guardrails are active

4. **Post-Deployment**:
   - Configure additional guardrails
   - Set up account factory
   - Enable additional AWS services

### Guardrails Management

#### Mandatory Guardrails (Always Active)
- **CloudTrail**: Organization-wide audit logging
- **Config**: Configuration compliance monitoring  
- **Cross-region data replication**: Disallowed by default
- **Root access keys**: Creation blocked

#### Strongly Recommended Guardrails
- **MFA for root user**: Required for all accounts
- **S3 bucket public access**: Blocked organization-wide
- **EBS encryption**: Required for all volumes
- **RDS encryption**: Required for all databases

### Account Factory Operations
- **Account Provisioning**: Streamlined through Service Catalog
- **Baseline Application**: Automatic security baseline deployment
- **Guardrail Inheritance**: New accounts inherit OU guardrails
- **SSO Integration**: Automatic access provisioning

## Hybrid Architecture Benefits

### Control Tower Responsibilities
- ✅ **Security OU Management**: Audit and log archive accounts
- ✅ **Baseline Security**: Foundational guardrails and monitoring
- ✅ **Compliance**: Built-in AWS best practices
- ✅ **Service Integration**: Native AWS service enablement

### Organizations Module Responsibilities  
- ✅ **Custom OUs**: Infrastructure and Workloads structures
- ✅ **Account Flexibility**: Non-Control Tower account management
- ✅ **Cost Optimization**: Manages only necessary resources
- ✅ **Scalability**: Supports diverse organizational needs

### Integration Points
```
Control Tower ←→ yaml-transform ←→ Organizations
     │                              │
     ▼                              ▼
Security OU                Infrastructure/Workloads OUs
(Audit/LogArchive)            (Custom account placement)
```

## Troubleshooting

### Common Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Landing Zone Drift** | Guardrails failing | Re-run Landing Zone setup |
| **Account Factory Errors** | Provisioning failures | Check IAM permissions and Service Catalog |
| **OU Management Conflicts** | Cross-module errors | Verify yaml-transform exclusions |
| **Provider Authentication** | Access denied errors | Verify management account credentials |

### Diagnostic Commands
```bash
# Check Control Tower status
aws controltower get-landing-zone --region us-east-1

# List guardrails
aws controltower list-enabled-controls --target-identifier "OU_ID"

# Verify account factory
aws servicecatalog list-portfolios --region us-east-1
```

## Security Considerations

### AWS SRA Alignment
- ✅ **Security OU Design**: Matches AWS reference architecture
- ✅ **Audit Account**: Serves as security services delegated administrator
- ✅ **Log Archive**: Centralized logging for compliance
- ✅ **Guardrails**: Implements AWS security best practices

### Compliance Features
- **Detective Controls**: Monitor configuration drift
- **Preventive Controls**: Block non-compliant actions
- **Audit Trail**: Complete activity logging
- **Compliance Reporting**: Built-in compliance dashboards

## Integration with Other Services

### Security Services Integration
- **GuardDuty**: Uses audit account as delegated administrator
- **Security Hub**: Centralizes findings in audit account
- **Config**: Provides compliance monitoring across all accounts
- **CloudTrail**: Organization-wide audit logging

### Identity Integration
- **SSO**: Integrates with account assignments
- **IAM**: Baseline IAM configuration
- **Account Access**: Centralized access management

## Future Enhancements

### Advanced Features
- 🚧 **Custom Guardrails**: Organization-specific compliance rules
- 🚧 **Account Factory Customization**: Custom provisioning workflows
- 🚧 **Enhanced Monitoring**: Advanced compliance dashboards
- 🚧 **Multi-Region Support**: Guardrails across multiple regions

---

*Last updated: July 31, 2025*
