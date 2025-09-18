locals {
  # AWS Security Reference Architecture (SRA) Account Types
  # These match AWS SRA and accreditation requirements and should not be changed
  # without careful consideration of compliance implications.
  sra_account_types = {
    # Core Foundation (Required by Control Tower)
    management = {
      name         = "management"
      display_name = "Management Account"
      required_ou  = "Root"
      description  = "AWS Organization management account"
    }
    log_archive = {
      name         = "log_archive"
      display_name = "Log Archive Account"
      required_ou  = "Security"
      description  = "Centralized logging and log storage"
    }
    audit = {
      name         = "audit"
      display_name = "Audit Account"
      required_ou  = "Security"
      description  = "Security audit and compliance"
    }
    # Security OU Accounts
    security_tooling = {
      name         = "security_tooling"
      display_name = "Security Tooling Account"
      required_ou  = "Security"
      description  = "Security tools, SIEM, and scanning"
    }
    # Infrastructure OU Accounts
    network = {
      name         = "network"
      display_name = "Network Account"
      required_ou  = "Infrastructure"
      description  = "Central network connectivity (TGW, DirectConnect)"
    }
    shared_services = {
      name         = "shared_services"
      display_name = "Shared Services Account"
      required_ou  = "Infrastructure"
      description  = "Shared infrastructure services (DNS, monitoring)"
    }
    # Workloads OU Accounts
    workload = {
      name         = "workload"
      display_name = "Workload Account"
      required_ou  = "Workloads"
      description  = "Application workload accounts"
    }
  }

  # This block defines which groups are assigned to each AWS SRA account type
  # Elements in each list must use the keys from local.aws_sso_groups
  # Each account type gets different groups based on its security and operational requirements per AWS SRA
  account_groups = {
    management       = ["aws_admin"]
    log_archive      = ["aws_admin", "aws_cyber_sec_eng", "aws_sec_auditor"]
    audit            = ["aws_admin", "aws_cyber_sec_eng", "aws_sec_auditor"]
    network          = ["aws_admin", "aws_cyber_sec_eng", "aws_net_admin", "aws_power_user", "aws_sec_auditor", "aws_sys_admin"]
    shared_services  = ["aws_admin", "aws_cyber_sec_eng", "aws_net_admin", "aws_power_user", "aws_sys_admin"]
    security_tooling = ["aws_admin", "aws_cyber_sec_eng", "aws_sec_auditor"]
    backup           = ["aws_admin", "aws_cyber_sec_eng", "aws_sys_admin"]
    workload         = ["aws_admin", "aws_workload_admin", "aws_cyber_sec_eng", "aws_sec_auditor"]
  }

  # This transforms the account_id_map into a structure that includes which groups
  # should be assigned to each account based on the account's role/type
  sso_group_mappings = {
    for account_name, account_id in var.account_id_map : account_id => {
      account_name = account_name
      groups       = contains(keys(var.account_role_mapping), account_name) ? local.account_groups[var.account_role_mapping[account_name]] : []
    }
  }

  # This creates individual assignment records for each group-to-account mapping
  # Used by aws_ssoadmin_account_assignment to create the actual assignments
  sso_group_assignments = flatten([
    for account_id, account in local.sso_group_mappings : [
      for group in account.groups : {
        account_id = account_id
        group_name = group
      }
    ]
  ])

  # These groups align with common AWS personas and include appropriate AWS managed policies
  # Each group creates both an IAM Identity Center permission set and (optionally) an Entra group
  aws_sso_groups = {
    aws_admin = {
      display_name       = "${var.project}-AwsAdmin"
      description        = "Administrator access provides full access to AWS services and resources."
      managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
    }
    aws_cyber_sec_eng = {
      display_name       = "${var.project}-AwsCyberSecEng"
      description        = "Provides access for DoD Cyber Security Service Provider (CSSP)."
      managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/PowerUserAccess" # TODO: build & replace policy
    }
    aws_net_admin = {
      display_name       = "${var.project}-AwsNetworkAdmin"
      description        = "Provides access for Networking connections such as for VPCs, route tables and Transit Gateways."
      managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/job-function/NetworkAdministrator"
    }
    aws_power_user = {
      display_name       = "${var.project}-AwsPowerUser"
      description        = "Provides additional permissions than a normal user to complete tasks."
      managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/PowerUserAccess"
    }
    aws_sec_auditor = {
      display_name       = "${var.project}-AwsSecAuditor"
      description        = "Grants access to read security configuration metadata. It is useful for software that audits the configuration of an AWS account."
      managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/SecurityAudit"
    }
    aws_sys_admin = {
      display_name       = "${var.project}-AwsSysAdmin"
      description        = "Grants full access permissions necessary for resources required for application and development operations."
      managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/job-function/SystemAdministrator"
    }
    aws_workload_admin = {
      display_name       = "${var.project}-AwsWorkloadAdmin"
      description        = "Workload-specific administrative access limited to application resources within the account boundary."
      managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/PowerUserAccess"
    }
  }
}
