locals {
  # Enhanced global tags with Project tag
  global_tags = merge(var.global_tags, {
    Project = var.project
  })

  # Load and flatten all account configurations from YAML files
  raw_account_configs = merge([
    for file in fileset("${var.config_directory}/accounts", "*.yaml") :
    yamldecode(file("${var.config_directory}/accounts/${file}"))
  ]...)

  # Load and flatten all OU configurations from YAML files  
  raw_ou_configs = merge([
    for file in fileset("${var.config_directory}/organizational-units", "*.yaml") :
    yamldecode(file("${var.config_directory}/organizational-units/${file}"))
  ]...)

  # Load SRA account types for validation and mapping
  sra_account_types = yamldecode(file("${path.module}/../../config/sra-account-types.yaml"))

  # Transform accounts: Simple YAML → Organizations module format
  # MAINTAINS RESOURCE KEYS: Uses account_id as key (same as current)
  aws_account_parameters = {
    for account_key, account_config in local.raw_account_configs :
    account_config.account_id => {
      name         = account_config.account_name
      email        = account_config.email
      ou           = account_config.ou
      lifecycle    = account_config.lifecycle
      account_type = account_config.account_type
      tags = merge(
        lookup(account_config, "additional_tags", {}),
        { AccountType = account_config.account_type },
        local.global_tags
      )
      create_govcloud = lookup(account_config, "create_govcloud", false)
    }
  }

  # Transform OUs: Simple YAML → Organizations module format
  # MAINTAINS RESOURCE KEYS: Uses OU name as key (same as current)
  organizational_units = {
    for ou_name, ou_config in local.raw_ou_configs :
    ou_name => {
      lifecycle = ou_config.lifecycle
      tags = merge(
        lookup(ou_config, "additional_tags", {}),
        local.global_tags
      )
    }
  }

  # Generate account_id_map for SSO module (account_name → account_id)
  account_id_map = {
    for account_id, account_data in local.aws_account_parameters :
    account_data.name => account_id
  }

  # Generate account_role_mapping for SSO module (account_name → account_type)
  account_role_mapping = {
    for account_id, account_data in local.aws_account_parameters :
    account_data.name => account_data.account_type
    if account_data.account_type != ""
  }

  # Extract Control Tower required account IDs for easy access
  management_account_id = try([
    for account_id, account_data in local.aws_account_parameters :
    account_id if account_data.account_type == "management"
  ][0], null)

  log_archive_account_id = try([
    for account_id, account_data in local.aws_account_parameters :
    account_id if account_data.account_type == "log_archive"
  ][0], null)

  audit_account_id = try([
    for account_id, account_data in local.aws_account_parameters :
    account_id if account_data.account_type == "audit"
  ][0], null)

  # Generate accounts_by_type structure (useful for security services)
  accounts_by_type = {
    for account_type in keys(local.sra_account_types) :
    account_type => {
      for account_id, account_data in local.aws_account_parameters :
      account_id => {
        name  = account_data.name
        email = account_data.email
        ou    = account_data.ou
      }
      if account_data.account_type == account_type
    }
  }

  # OU resolution for Control Tower integration
  # When Control Tower is enabled, some OUs are managed by Control Tower
  control_tower_managed_ous = var.control_tower_enabled ? ["Security", "Sandbox"] : []

  # Split OUs into those managed by organizations module vs Control Tower
  organizations_managed_ous = {
    for ou_name, ou_config in local.organizational_units :
    ou_name => ou_config
    if !contains(local.control_tower_managed_ous, ou_name)
  }

  # Split accounts based on whether they'll be placed in Control Tower-managed OUs
  # Accounts going to Control Tower OUs should be left at Root initially
  # Control Tower will move them to the correct OU during landing zone deployment
  control_tower_managed_accounts = {
    for account_id, account_data in local.aws_account_parameters :
    account_id => merge(account_data, {
      ou = "Root" # Override OU placement - Control Tower will handle it
    })
    if contains(local.control_tower_managed_ous, account_data.ou)
  }

  organizations_managed_accounts = {
    for account_id, account_data in local.aws_account_parameters :
    account_id => account_data
    if !contains(local.control_tower_managed_ous, account_data.ou)
  }

  # Provide the appropriate account set for organizations module
  # When Control Tower is enabled, exclude Control Tower-managed accounts from Organizations
  organizations_account_parameters = var.control_tower_enabled ? local.organizations_managed_accounts : local.aws_account_parameters

  # Provide a complete OU mapping for account placement
  # This combines manually created OUs with Control Tower-managed OUs
  ou_placement_config = {
    organizations_managed_ous = local.organizations_managed_ous
    control_tower_managed_ous = local.control_tower_managed_ous
    all_ou_names              = keys(local.organizational_units)
  }

  # Validation checks (when enabled)
  validation_errors = var.enable_validation ? concat(
    # Account ID format validation
    [for account_id in keys(local.aws_account_parameters) :
    "Invalid account ID format: ${account_id}" if !can(regex("^[0-9]{12}$", account_id))],

    # Email format validation
    [for account_id, account in local.aws_account_parameters :
      "Invalid email format for account ${account_id}: ${account.email}"
    if !can(regex("^\\S+@\\S+\\.\\S+$", account.email))],

    # Lifecycle validation
    [for account_id, account in local.aws_account_parameters :
      "Invalid lifecycle for account ${account_id}: ${account.lifecycle} (must be 'prod' or 'nonprod')"
    if !contains(["prod", "nonprod"], account.lifecycle)],

    # OU lifecycle validation
    [for ou_name, ou in local.organizational_units :
      "Invalid lifecycle for OU ${ou_name}: ${ou.lifecycle} (must be 'prod' or 'nonprod')"
    if !contains(["prod", "nonprod"], ou.lifecycle)],

    # Account type validation against SRA types
    [for account_id, account in local.aws_account_parameters :
      "Invalid account_type for account ${account_id}: ${account.account_type} (not found in SRA account types)"
    if account.account_type != "" && !contains(keys(local.sra_account_types), account.account_type)]
  ) : []
}

# Configuration validation check
check "yaml_configuration_validation" {
  assert {
    condition     = length(local.validation_errors) == 0
    error_message = "YAML configuration validation failed:\n${join("\n", local.validation_errors)}"
  }
}
