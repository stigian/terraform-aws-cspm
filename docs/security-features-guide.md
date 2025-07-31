# Security Features Guide

This guide outlines the security features and controls implemented in the terraform-aws-cspm module for DoD Zero Trust CSPM compliance.

---

## 🛡️ Security Architecture Overview

The module implements a **cloud-native DISA SCCA (Secure Cloud Computing Architecture)** with AWS Security Reference Architecture (SRA) patterns as fallback when SCCA documentation is insufficient.

### Key Security Principles
- **Zero Trust**: Least privilege access with continuous verification
- **Defense in Depth**: Multiple layers of security controls
- **Compliance First**: DISA SCCA compliance with automated guardrails
- **Centralized Monitoring**: Unified security posture management

---

## 🏛️ Core Security Components

### 1. Organizational Security Boundaries

#### Account Isolation
```yaml
# Each account provides strong isolation boundary
accounts:
  "123456789012":
    name: "YourOrg-Security-Audit"
    account_type: "audit"        # Dedicated security monitoring
    ou: "Security"               # Restrictive OU with security guardrails
    lifecycle: "prod"            # Production-level controls
```

#### OU-Based Governance
- **Security OU**: Audit, log archive, and security accounts with enhanced controls
- **Infrastructure OU**: Network and shared services with infrastructure-specific policies
- **Workloads OU**: Application accounts with workload-appropriate restrictions
- **Root**: Management account only, minimal direct workload placement

### 2. Identity and Access Management

#### IAM Identity Center (SSO) Integration
```hcl
# Centralized identity with role-based access
permission_sets = {
  aws-admin      = "Administrative access with MFA"
  read-only      = "Read-only access across accounts"
  security-admin = "Security-focused administrative access"
  network-admin  = "Network infrastructure management"
}
```

#### Cross-Account Role Strategy
- **OrganizationAccountAccessRole**: Standard cross-account access pattern
- **Least Privilege**: Minimal permissions for each role type
- **MFA Enforcement**: Multi-factor authentication required for privileged access
- **Session Limits**: Time-bound access with automatic expiration

### 3. Control Tower Security Guardrails

#### Preventive Guardrails
- **Mandatory**: Baseline security controls that cannot be disabled
- **Strongly Recommended**: Additional security controls for enhanced protection
- **Elective**: Optional controls for specific compliance requirements

#### Detective Guardrails
- **Config Rules**: Continuous compliance monitoring
- **CloudTrail Monitoring**: API activity tracking and alerting
- **Account Drift Detection**: Unauthorized changes detection

---

## 🔐 Data Protection & Encryption

### KMS Key Management

#### Control Tower Enhanced KMS
```hcl
# Organization-scoped encryption with SSO integration
resource "aws_kms_key" "control_tower" {
  description         = "Enhanced KMS key for Control Tower resources"
  key_usage          = "ENCRYPT_DECRYPT"
  key_spec           = "SYMMETRIC_DEFAULT"
  enable_key_rotation = true
  
  policy = {
    # Organizational boundaries with aws:PrincipalOrgID
    # SSO role-based access patterns
    # Management account scope restrictions
  }
}
```

#### Encryption Standards
- **At Rest**: All data encrypted using AWS KMS
- **In Transit**: TLS 1.2+ for all communications
- **Key Rotation**: Automatic annual key rotation enabled
- **Access Control**: Principle of least privilege for key usage

### Data Residency & Sovereignty
- **Regional Isolation**: Resources deployed only in approved regions
- **Cross-Border Restrictions**: Data cannot leave specified geographic boundaries
- **Compliance Zones**: GovCloud vs Commercial partitions automatically detected

---

## 📊 Monitoring & Compliance

### Centralized Logging Architecture

#### CloudTrail Organization Trail
```yaml
# All API activity logged to central audit account
cloudtrail:
  organization_trail: true
  log_destination: "Log Archive Account"
  integrity_validation: true
  kms_encryption: true
```

#### Config Organization Rules
- **Configuration Compliance**: Continuous resource configuration monitoring
- **Drift Detection**: Unauthorized changes automatically detected
- **Remediation**: Automatic corrective actions for non-compliant resources
- **Compliance Reporting**: Centralized compliance dashboard

### Security Hub Integration
```hcl
# Centralized security findings aggregation
module "securityhub" {
  source = "../modules/securityhub"
  
  audit_account_id = var.audit_account_id
  finding_format   = "ASFF"  # AWS Security Finding Format
  
  # Automatic integration with:
  # - AWS Config
  # - GuardDuty
  # - Inspector
  # - IAM Access Analyzer
}
```

### Cross-Account Security Services

#### GuardDuty Threat Detection
- **Machine Learning**: Behavioral analysis for threat detection
- **Threat Intelligence**: AWS and third-party threat feeds
- **Cross-Account**: Centralized management from audit account
- **Automated Response**: Integration with security orchestration

#### Inspector Vulnerability Assessment
- **Application Assessment**: EC2 and container vulnerability scanning
- **Network Reachability**: Network path analysis
- **Continuous Monitoring**: Ongoing assessment of security posture
- **Integration**: Findings forwarded to Security Hub

---

## 🚨 Incident Response & Forensics

### Detective Security Service
```hcl
# Security investigation and analysis
module "detective" {
  source = "../modules/detective"
  
  audit_account_id = var.audit_account_id
  data_sources = {
    vpc_flow_logs    = true
    dns_logs         = true
    kubernetes_audit = true
  }
}
```

### Forensic Capabilities
- **Behavioral Analysis**: Machine learning-based threat detection
- **Visual Investigation**: Interactive security investigation tools
- **Data Correlation**: Cross-service security event correlation
- **Timeline Analysis**: Chronological security event reconstruction

### Incident Response Integration
- **Automated Alerting**: Real-time security event notifications
- **Playbook Integration**: Standardized response procedures
- **Evidence Collection**: Automated forensic artifact gathering
- **Compliance Reporting**: Incident documentation for audits

---

## 🎯 Compliance & Auditing

### DISA SCCA Compliance

#### Architecture Compliance
- ✅ **Boundary Protection**: Network segmentation and access controls
- ✅ **Data Protection**: Encryption and data loss prevention
- ✅ **Identity Management**: Centralized authentication and authorization
- ✅ **Monitoring**: Continuous security monitoring and alerting

#### Controls Implementation
- ✅ **AC-3**: Access Enforcement through IAM and SSO
- ✅ **AU-2**: Audit Events via CloudTrail and Config
- ✅ **CA-7**: Continuous Monitoring through Security Hub
- ✅ **SC-8**: Transmission Confidentiality via TLS/KMS

### AWS Security Reference Architecture (SRA)

#### Account Structure
- ✅ **Management Account**: Organizational control and billing
- ✅ **Security Account**: Centralized security monitoring (audit)
- ✅ **Log Archive Account**: Centralized logging and retention
- ✅ **Network Account**: Centralized network connectivity

#### Security Services
- ✅ **Config**: Configuration compliance monitoring
- ✅ **CloudTrail**: API activity logging
- ✅ **GuardDuty**: Threat detection
- ✅ **Security Hub**: Security findings aggregation

---

## 🔧 Security Operations

### Day 1 Security Setup
```bash
# Initial security baseline deployment
tofu apply -target=module.organizations
tofu apply -target=module.controltower
tofu apply -target=module.sso

# Enable cross-account security services
tofu apply -target=module.guardduty
tofu apply -target=module.securityhub
```

### Ongoing Security Maintenance

#### Daily Security Tasks
- [ ] Review Security Hub critical findings
- [ ] Monitor GuardDuty threat detections
- [ ] Verify Config compliance status
- [ ] Check CloudTrail for anomalous activity

#### Weekly Security Reviews
- [ ] Analyze IAM access patterns
- [ ] Review cross-account role usage
- [ ] Validate encryption key usage
- [ ] Update threat intelligence feeds

#### Monthly Security Assessments
- [ ] Conduct access review and cleanup
- [ ] Update security baselines
- [ ] Review and test incident response procedures
- [ ] Assess compliance posture

### Security Metrics & KPIs
- **Config Compliance Score**: Percentage of compliant resources
- **Security Hub Findings**: Critical/High finding trends
- **GuardDuty Detections**: Threat detection volume and types
- **Access Patterns**: Anomalous authentication activities

---

## 🛠️ Security Configuration Examples

### Secure Account Provisioning
```yaml
# Security-first account configuration
accounts:
  "123456789012":
    name: "YourOrg-Workload-Prod"
    email: "aws-workload-prod@yourorg.com"
    ou: "Workloads_Prod"           # Production-level controls
    lifecycle: "prod"              # Enhanced security requirements
    account_type: "workload"       # Workload-specific policies
    tags:
      DataClassification: "CUI"    # Controlled Unclassified Information
      SecurityZone: "Internal"     # Internal security boundary
      ComplianceFramework: "DISA"  # DISA SCCA compliance required
```

### Cross-Account Security Service Configuration
```hcl
# Centralized security services deployment
module "cross_account_security" {
  source = "../modules/guardduty"
  
  # Audit account as delegated administrator
  audit_account_id = "345678901234"
  
  # Automatic member enrollment
  auto_enable_organization = true
  
  # Enhanced threat detection
  datasources = {
    s3_logs                = true
    kubernetes_audit_logs  = true
    malware_protection     = true
  }
  
  global_tags = {
    SecurityService = "GuardDuty"
    Purpose        = "ThreatDetection"
  }
}
```

---

## 📋 Security Validation Checklist

### Pre-Deployment Security Validation
- [ ] **Account Structure**: Verify SRA-compliant account placement
- [ ] **IAM Roles**: Confirm OrganizationAccountAccessRole exists
- [ ] **KMS Keys**: Validate encryption key policies
- [ ] **Network Isolation**: Verify VPC and subnet configurations
- [ ] **Compliance Tags**: Ensure required compliance metadata

### Post-Deployment Security Verification
- [ ] **Control Tower Guardrails**: Verify all preventive controls active
- [ ] **Security Service Integration**: Confirm GuardDuty/Security Hub operational
- [ ] **Logging Pipeline**: Validate CloudTrail and Config logging
- [ ] **Access Controls**: Test cross-account role assumptions
- [ ] **Monitoring Alerts**: Verify security alerting functionality

---

*This security guide is maintained by the security team and updated with each module release.*  
*For security questions or incident reporting, contact the security operations team.*
