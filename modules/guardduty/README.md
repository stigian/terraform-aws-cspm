# GuardDuty Module

## Overview

This module deploys and configures AWS GuardDuty for organization-wide threat detection and monitoring in DoD Zero Trust CSPM environments. It establishes the audit account as the delegated administrator and enables comprehensive protection plans aligned with DISA SCCA threat detection requirements.

**Key Architecture Pattern**: Cross-account security service deployment with audit account as delegated administrator - provides centralized threat detection across all organizational accounts with configurable protection plans.

## Architecture Pattern

### Organization-Wide Threat Detection
- **Delegated Administration**: Audit account serves as GuardDuty organization administrator
- **Auto-Enrollment**: Automatically enables GuardDuty across all organization member accounts
- **Centralized Management**: Single control plane for threat detection policies and findings
- **Cross-Account Monitoring**: Aggregates security findings from all organizational accounts

### Protection Plan Strategy
**Priority 1 - DISA SCCA Recommended (Default: Enabled)**:
- **S3 Protection**: Monitors S3 data events for suspicious access patterns and data exfiltration
- **Runtime Monitoring**: eBPF-based monitoring for EC2, EKS, and ECS workloads (requires agent deployment)

**Priority 2 - Conditional Recommendations (Default: Disabled)**:
- **Malware Protection (EC2)**: EBS volume scanning when suspicious activity detected
- **Lambda Protection**: VPC Flow Log monitoring for Lambda network activity
- **EKS Protection**: Kubernetes audit log monitoring (only if using EKS clusters)
- **RDS Protection**: Aurora database login activity anomaly detection

**Priority 3 - Specialized Use Cases (Default: Disabled)**:
- **Malware Protection (S3)**: Selective bucket-level malware scanning for untrusted sources

### Multi-Provider Architecture
Uses dual provider pattern:
- **Management Account Provider**: For organization-level GuardDuty administration setup
- **Audit Account Provider**: For detector configuration and protection plan management

## Deployment Requirements

### Prerequisites
1. **Organizations Foundation**: Must deploy after Organizations module establishes audit account
   ```hcl
   module "guardduty" {
     source = "./modules/guardduty"
     
     audit_account_id = module.organizations.audit_account_id
   }
   ```

2. **Provider Configuration**: Management account for organization setup, audit account for detector management
   ```hcl
   # Management account provider (default)
   provider "aws" {
     profile = "management-account-profile"
     region  = "us-gov-west-1"
   }
   
   # Audit account provider (for GuardDuty management)
   provider "aws" {
     alias   = "audit"
     profile = "audit-account-profile"
     region  = "us-gov-west-1"
     assume_role {
       role_arn = "arn:aws-us-gov:iam::${var.audit_account_id}:role/OrganizationAccountAccessRole"
     }
   }
   ```

3. **Cross-Account Role**: OrganizationAccountAccessRole must exist in audit account

### Configuration Variables
- **`audit_account_id`**: Required - Account ID for GuardDuty delegated administrator
- **`cross_account_role_name`**: Role name for audit account access (default: OrganizationAccountAccessRole)
- **Protection Plan Flags**: Boolean variables for each protection plan (see variables.tf for full list)
- **`malware_protection_s3_buckets`**: List of bucket names for selective S3 malware protection

### Runtime Monitoring Prerequisites
When `enable_runtime_monitoring = true`:
- **Agent Deployment**: Requires GuardDuty Runtime Monitoring agent on EC2 instances
- **EKS Integration**: Kubernetes add-on or DaemonSet deployment for EKS clusters
- **ECS Integration**: Task definition modifications for ECS Fargate workloads

## Troubleshooting

### Organization Administrator Issues
1. **Delegation Conflicts**: Ensure no existing GuardDuty organization admin before deployment
2. **Account Access**: Verify OrganizationAccountAccessRole exists in audit account with proper permissions
3. **Cross-Account Failures**: Check assume role permissions and trusted relationships

### Protection Plan Configuration Problems
- **Runtime Monitoring Agent Issues**: Verify agent installation and network connectivity
- **S3 Protection False Positives**: Review CloudTrail integration and data access patterns
- **Cost Management**: Monitor GuardDuty usage, especially for high-volume protection plans

### Regional Deployment Constraints
```bash
# Verify GuardDuty availability in target region
aws guardduty list-detectors --region us-gov-west-1
```

## Integration with Other Modules

### Organizations Module Integration
- **Foundation Dependency**: Requires audit account ID from organizations module output
- **Account Inventory**: Automatically enrolls all organization member accounts
- **Cross-Account Structure**: Uses organizational account structure for security service deployment

### Security Hub Integration
- **Finding Aggregation**: GuardDuty findings automatically sent to Security Hub when configured
- **Compliance Mapping**: Threat detection findings mapped to security standards and frameworks
- **Centralized Dashboard**: Combined security posture view across all organizational accounts

### Detective Integration
- **Investigation Context**: GuardDuty findings provide input for Detective investigation graphs
- **Behavioral Analysis**: Combines threat detection with user/resource behavior analysis
- **Incident Response**: Integrated workflow for threat investigation and response

## DoD-Specific Considerations

### DISA SCCA Threat Detection Requirements
- **VDSS Component**: Implements Virtual Data Center Security Stack threat detection capabilities
- **Continuous Monitoring**: Provides 24/7 threat detection required by SCCA architecture
- **Multi-Account Coverage**: Ensures threat detection across all SCCA component accounts

### GovCloud Deployment Patterns
- **Partition-Aware**: Handles GovCloud-specific ARN formats and service availability
- **Regional Availability**: Optimized for us-gov-west-1 and us-gov-east-1 deployments
- **Compliance Integration**: Aligns with DoD security monitoring and incident response requirements

### Operational Security Features
- **Enterprise Integration**: Compatible with existing DoD security operations centers (SOCs)
- **Finding Classification**: Supports classification and handling requirements for sensitive findings
- **Audit Trail**: Comprehensive logging for compliance and incident investigation requirements

### Cost Management for DoD Scale
- **Protection Plan Optimization**: Default configuration balances security coverage with cost efficiency
- **Enterprise Volume**: Designed for large-scale DoD deployments with hundreds of accounts
- **Budget Controls**: Configurable protection plans to manage costs while maintaining security posture

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |
| <a name="provider_aws.audit"></a> [aws.audit](#provider\_aws.audit) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_guardduty_detector.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_guardduty_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_guardduty_organization_configuration_feature.eks_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.lambda_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.malware_protection_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.rds_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.runtime_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |
| [aws_guardduty_organization_configuration_feature.s3_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration_feature) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audit_account_id"></a> [audit\_account\_id](#input\_audit\_account\_id) | AWS account ID that will serve as the GuardDuty organization administrator (delegated admin) | `string` | n/a | yes |
| <a name="input_cross_account_role_name"></a> [cross\_account\_role\_name](#input\_cross\_account\_role\_name) | Name of the role to assume in the audit account for GuardDuty management | `string` | `"OrganizationAccountAccessRole"` | no |
| <a name="input_enable_eks_protection"></a> [enable\_eks\_protection](#input\_enable\_eks\_protection) | Enable EKS Protection to monitor Kubernetes audit logs (only if using EKS clusters) | `bool` | `false` | no |
| <a name="input_enable_lambda_protection"></a> [enable\_lambda\_protection](#input\_enable\_lambda\_protection) | Enable Lambda Protection to monitor VPC Flow Logs for Lambda network activity | `bool` | `false` | no |
| <a name="input_enable_malware_protection_ec2"></a> [enable\_malware\_protection\_ec2](#input\_enable\_malware\_protection\_ec2) | Enable Malware Protection for EC2 to scan EBS volumes when suspicious activity is detected. Note: Most enterprise customers use dedicated EDR solutions (Defender, CrowdStrike, etc.) | `bool` | `false` | no |
| <a name="input_enable_malware_protection_s3"></a> [enable\_malware\_protection\_s3](#input\_enable\_malware\_protection\_s3) | Enable S3 Malware Protection for specific untrusted buckets (not organization-wide) | `bool` | `false` | no |
| <a name="input_enable_rds_protection"></a> [enable\_rds\_protection](#input\_enable\_rds\_protection) | Enable RDS Protection to monitor Aurora database login activity for anomalies | `bool` | `false` | no |
| <a name="input_enable_runtime_monitoring"></a> [enable\_runtime\_monitoring](#input\_enable\_runtime\_monitoring) | Enable Runtime Monitoring for EC2, EKS, and ECS workloads using eBPF-based agents. See docs/README.md for agent deployment prerequisites. | `bool` | `true` | no |
| <a name="input_enable_s3_protection"></a> [enable\_s3\_protection](#input\_enable\_s3\_protection) | Enable S3 Protection to monitor S3 data events for suspicious access patterns | `bool` | `true` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags to apply to all GuardDuty resources | `map(string)` | `{}` | no |
| <a name="input_malware_protection_s3_buckets"></a> [malware\_protection\_s3\_buckets](#input\_malware\_protection\_s3\_buckets) | List of S3 bucket names to enable malware protection (only used if enable\_malware\_protection\_s3 is true) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_guardduty_status"></a> [guardduty\_status](#output\_guardduty\_status) | Complete GuardDuty deployment status including organization configuration and protection plans |
<!-- END_TF_DOCS -->
