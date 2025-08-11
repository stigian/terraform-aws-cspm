locals {
  # TODO: add view only role to sso and entra
  # TODO: incorporate PIM for Global Administrator and AWS Administrator

  # Group ownership - conditionally include Entra admins
  group_owners = var.enable_entra_integration ? concat(
    [data.azuread_client_config.current[0].object_id],
    var.entra_group_admin_object_ids
  ) : []

  # Combine existing admin user (if provided) with new users to create
  all_admin_users = var.initial_admin_users

  # Create group memberships for both existing and new users
  initial_admin_group_memberships = merge(
    # Group memberships for existing admin user (if provided)
    var.existing_admin_user_id != null ? {
      "${var.existing_admin_user_id}-aws_admin" = {
        user_id          = var.existing_admin_user_id
        group_name       = "aws_admin"
        is_existing_user = true
      }
    } : {},

    # Group memberships for new users to create
    {
      for pair in flatten([
        for user in local.all_admin_users : [
          for group in(user.admin_level == "full" ?
            ["aws_admin"] :
            ["aws_cyber_sec_eng", "aws_sec_auditor"]
            ) : {
            user_name        = user.user_name
            group_name       = group
            user_data        = user
            is_existing_user = false
          }
        ]
      ]) : "${pair.user_name}-${pair.group_name}" => pair
    }
  )

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
    workload         = ["aws_admin", "aws_power_user", "aws_cyber_sec_eng", "aws_sec_auditor", "aws_sys_admin"]
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
  }

  # These groups are for managing Entra ID administrative roles and permissions
  # Only created when enable_entra_integration is true
  entra_security_groups = {
    entra_app_admin = {
      display_name = "EntraAppAdmin"
      description  = "Application Administrator"
    }
    entra_auth_policy_admin = {
      display_name = "EntraAuthPolicyAdmin"
      description  = "Authentication Policy Administrator"
    }
    entra_cond_access_admin = {
      display_name = "EntraCondAccessAdmin"
      description  = "Conditional Access Administrator"
    }
    entra_dir_reader = {
      display_name = "EntraDirReader"
      description  = "Directory Reader"
    }
    entra_global_admin = {
      display_name = "EntraGlobalAdmin"
      description  = "Global Administrator"
    }
    entra_groups_admin = {
      display_name = "EntraGroupsAdmin"
      description  = "Groups Administrator"
    }
    entra_priv_role_admin = {
      display_name = "EntraPrivRoleAdmin"
      description  = "Privileged Role Administrator"
    }
    entra_sec_reader = {
      display_name = "EntraSecReader"
      description  = "Security Reader"
    }
  }
}
