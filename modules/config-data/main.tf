locals {
  # Load account configurations from YAML files
  account_configs = merge([
    for file in fileset("${var.config_directory}/accounts", "*.yaml") : {
      (trimsuffix(basename(file), ".yaml")) = yamldecode(file("${var.config_directory}/accounts/${file}"))
    }
  ]...)

  # Load OU configurations from YAML files
  ou_configs = merge([
    for file in fileset("${var.config_directory}/organizational-units", "*.yaml") : {
      (trimsuffix(basename(file), ".yaml")) = yamldecode(file("${var.config_directory}/organizational-units/${file}"))
    }
  ]...)

  # Load SSO configurations from YAML files
  sso_configs = merge([
    for file in fileset("${var.config_directory}/sso", "*.yaml") : {
      (trimsuffix(basename(file), ".yaml")) = yamldecode(file("${var.config_directory}/sso/${file}"))
    }
  ]...)

  # Transform account configurations to module-compatible format
  aws_account_parameters = {
    for name, config in local.account_configs :
    config.account_id => {
      name      = config.account_name
      email     = config.email
      ou        = config.ou
      lifecycle = config.lifecycle
      tags = merge(
        lookup(config, "additional_tags", {}),
        { AccountType = config.account_type },
        var.global_tags
      )
      create_govcloud = lookup(config, "create_govcloud", false)
    }
  }

  # Transform OU configurations to module-compatible format
  organizational_units = {
    for name, ou_data in local.ou_configs :
    name => {
      lifecycle = ou_data.lifecycle
      tags = merge(
        lookup(ou_data, "additional_tags", {}),
        var.global_tags
      )
    }
  }

  # Transform SSO configurations
  sso_groups              = lookup(local.sso_configs, "groups", {})
  sso_account_assignments = lookup(local.sso_configs, "account_assignments", {})
}
