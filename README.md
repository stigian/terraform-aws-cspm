# terraform-aws-cspm

This module configures Cloud Security Posture Management (CSPM) in support of the DoD Zero Trust strategy. The design relies on the AWS Control Tower Landing Zone baseline version 3.3 as a starting point. Additional services are delegated, activated, and configured across the entire AWS Organization including:

- GuardDuty
- Detective
- Inspector
- Security Hub
- Config
- CloudTrail
- IAM Identity Center

[AWS Security Services Best Practices](https://aws.github.io/aws-security-services-best-practices/) serves as a guide for the default configuration. Configurations for non-security services like AWS Config are also included to ensure compliance with the DoD Zero Trust strategy.

# Service Descriptions

## GuardDuty

Amazon GuardDuty is a threat detection service that continuously monitors for malicious activity and unauthorized behavior to protect your AWS accounts and workloads. GuardDuty is enabled in all accounts in the AWS Organization. The audit account is the master account for GuardDuty. Member accounts are enabled and configured to send findings to the master account.

## Detective

Amazon Detective makes it easy to analyze, investigate, and quickly identify the root cause of security findings or suspicious activities. Detective automatically collects log data from your AWS resources and uses machine learning, statistical analysis, and graph theory to help you visualize and conduct faster and more efficient security investigations.


## Inspector

Amazon Inspector is a vulnerability management service that continuously monitors your AWS workloads for software vulnerabilities and unintended network exposure. Amazon Inspector automatically discovers and scans running Amazon EC2 instances, container images in Amazon Elastic Container Registry (Amazon ECR), and AWS Lambda functions.


## Security Hub

AWS Security Hub provides you with a comprehensive view of your security state within AWS and helps you check your environment against security industry standards and best practices. Security Hub is enabled in all accounts in the AWS Organization. The audit account is the master account for Security Hub. Member accounts are enabled and configured to send findings to the master account.

## Config

AWS Config provides a detailed view of the resources associated with your AWS account, including how they are configured, how they are related to one another, and how the configurations and their relationships have changed over time. AWS Config resources provisioned by AWS Control Tower are tagged automatically with `aws-control-tower` and a value of `managed-by-control-tower`.

## CloudTrail

AWS Control Tower configures AWS CloudTrail to enable centralized logging and auditing for all accounts. With CloudTrail, the management account can review administrative actions and lifecycle events for member accounts.


## IAM Identity Center

AWS Control Tower configures IAM Identity Center to provide a centralized view of identity and access management (IAM) activity across all accounts in the AWS Organization. IAM Identity Center provides a single location to view and manage IAM activity, including changes to IAM policies, roles, and users.


# Pre-deployment steps

In Govcloud, create and add accounts to the AWS Organization. The accounts do not need to be placed into Organizational Units (OUs) ahead of time. Control Tower will place the log archive and audit accounts into the proper OUs. We recommend moving the hub-and-spoke account to the _Sandbox_ OU after the module has finished provisioning. You may wish to create additional OUs like _Production_ or _Development_ to suit your specific needs. These OUs will inherit the baseline guardrails applied at the root of the Organization. The minimum accounts you need to create are:

- Management
- Hub-and-spoke
- Log archive
- Audit


# Post-deployment steps


## GuardDuty

> [!NOTE]
> Enabling member accounts is not retroactive, so you must enable them manually.

1. Login to the audit account
1. Navigate to _Accounts_ in the left hand pane
1. Verify every account _Status_ column shows _Enabled_
1. If not, select the checkbox next to each account, click _Actions_, click _Add member_


## Detective

> [!NOTE]
> Enabling member accounts is not retroactive, so you must enable them manually.

1. Login to the audit account
1. Navigate to _Settings_ -> _Account management_ in the left hand pane
1. Verify member accounts _Status_ column shows _Enabled_
1. If not, simply click the _Enable all accounts_ button


## Inspector

No action required.


## Control Tower

No action required.

If in the future you need to enroll/onboard new accounts to Control Tower, see these references:

- [Enroll an existing AWS account | AWS Docs](https://docs.aws.amazon.com/controltower/latest/userguide/enroll-account.html)
- [Field Notes: Enroll Existing AWS Accounts into AWS Control Tower | AWS Blogs](https://aws.amazon.com/blogs/architecture/field-notes-enroll-existing-aws-accounts-into-aws-control-tower/) for more information.


## Security Hub

No action required.

Insight categories for Critical and High findings are automatically configured. Depending on your specific security posture you may wish to [fine tune the Security Standard controls](https://aws.github.io/aws-security-services-best-practices/guides/security-hub/#fine-tuning-security-standard-controls) to reduce noise.


## Config

No action required.


## CloudTrail

No action required.


## IAM Identity Center

No action required.

Control Tower applies a basic configuration for IAM Identity Center in the management account. We choose _not_ to delegate administration of IAM Identity Center to another account, instead leaving it in the management account. This is because the management account is the root account and has the highest level of permissions. We recommend that you do not delegate IAM Identity Center to another account unless you have a specific use case that requires it.

Customizations to IAM Identity Center such as transitioning to an external identity provider may be applied separately. See the [AWS docs](https://docs.aws.amazon.com/singlesignon/latest/userguide/manage-your-identity-source-considerations.html#changing-from-idc-and-idp) for more information.
