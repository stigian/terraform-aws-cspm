# Extending OUs and Lifecycles

This guide explains how to extend the terraform-aws-cspm module with additional Organizational Units (OUs) and lifecycle phases. The architecture has been designed to be highly extensible with minimal code changes required.

## Architecture Overview

The module uses a flexible, YAML-driven configuration approach:

- **OUs are dynamically created** - No hardcoded OU references
- **Simple object structure** - Each OU needs only `lifecycle` and optional `tags`
- **Flexible account placement** - Accounts reference OUs by name
- **YAML-driven account types** - Account types defined in `config/sra-account-types.yaml`
- **Minimal validation** - Only essential validations that are easy to update

## Adding New OUs

Adding new OUs is straightforward and requires no code changes to the module itself.

### Method 1: Override in terraform.tfvars

Add new OUs to your `terraform.tfvars` file:

```hcl
organizational_units = {
  # Keep all existing OUs...
  Security               = { lifecycle = "prod" }
  Infrastructure_Prod    = { lifecycle = "prod" }
  Infrastructure_NonProd = { lifecycle = "nonprod" }
  Workloads_Prod         = { lifecycle = "prod" }
  Workloads_NonProd      = { lifecycle = "nonprod" }
  Sandbox                = { lifecycle = "nonprod" }
  Policy_Staging         = { lifecycle = "nonprod" }
  Suspended              = { lifecycle = "nonprod" }
  
  # Add new OUs:
  Development            = { lifecycle = "nonprod" }
  Training               = { lifecycle = "nonprod" }
  Research               = { lifecycle = "sandbox" }  # if using new lifecycle
  
  # Add custom tags if needed:
  SpecialProject = {
    lifecycle = "nonprod"
    tags = {
      Owner       = "SpecialTeam"
      CostCenter  = "12345"
      Environment = "experimental"
    }
  }
}
```

### Method 2: Update Module Defaults

If you want the new OUs to be available by default, update the `default` block in `modules/organizations/variables.tf`:

```hcl
default = {
  Security               = { lifecycle = "prod" }
  Infrastructure_Prod    = { lifecycle = "prod" }
  Infrastructure_NonProd = { lifecycle = "nonprod" }
  Workloads_Prod         = { lifecycle = "prod" }
  Workloads_NonProd      = { lifecycle = "nonprod" }
  Sandbox                = { lifecycle = "nonprod" }
  Policy_Staging         = { lifecycle = "nonprod" }
  Suspended              = { lifecycle = "nonprod" }
  
  # New default OUs:
  Development            = { lifecycle = "nonprod" }
  Training               = { lifecycle = "nonprod" }
}
```

### Using New OUs

Once defined, accounts can reference the new OUs:

```hcl
aws_account_parameters = {
  "123456789012" = {
    name         = "Development-Account-1"
    email        = "dev1@yourcorp.com"
    ou           = "Development"          # Reference the new OU
    lifecycle    = "nonprod"
    account_type = "workload"
  }
}
```

## Adding New Lifecycles

Adding new lifecycle phases requires updating validation rules in two places within `modules/organizations/variables.tf`.

### Step 1: Update OU Lifecycle Validation

Find the `organizational_units` variable validation (around line 82):

```hcl
# Before:
validation {
  condition     = alltrue([for v in values(var.organizational_units) : contains(["prod", "nonprod"], v.lifecycle)])
  error_message = "OU lifecycle must be 'prod' or 'nonprod'."
}

# After:
validation {
  condition     = alltrue([for v in values(var.organizational_units) : contains(["prod", "nonprod", "sandbox", "development"], v.lifecycle)])
  error_message = "OU lifecycle must be 'prod', 'nonprod', 'sandbox', or 'development'."
}
```

### Step 2: Update Account Lifecycle Validation

Find the `aws_account_parameters` variable validation (around line 134):

```hcl
# Before:
validation {
  condition     = alltrue([for v in values(var.aws_account_parameters) : contains(["prod", "nonprod"], v.lifecycle)])
  error_message = "Account lifecycle must be 'prod' or 'nonprod'."
}

# After:
validation {
  condition     = alltrue([for v in values(var.aws_account_parameters) : contains(["prod", "nonprod", "sandbox", "development"], v.lifecycle)])
  error_message = "Account lifecycle must be 'prod', 'nonprod', 'sandbox', or 'development'."
}
```

### Step 3: Use New Lifecycles

Once validated, you can use the new lifecycles:

```hcl
organizational_units = {
  Infrastructure_Sandbox = { lifecycle = "sandbox" }
  Workloads_Development  = { lifecycle = "development" }
}

aws_account_parameters = {
  "123456789012" = {
    lifecycle    = "sandbox"
    ou           = "Infrastructure_Sandbox"
    # ... other fields
  }
}
```

## Example: Adding a Complete "Staging" Environment

Here's a complete example of adding a staging lifecycle with associated OUs:

### 1. Update Validation Rules

```hcl
# In modules/organizations/variables.tf

# OU validation:
validation {
  condition     = alltrue([for v in values(var.organizational_units) : contains(["prod", "nonprod", "staging"], v.lifecycle)])
  error_message = "OU lifecycle must be 'prod', 'nonprod', or 'staging'."
}

# Account validation:
validation {
  condition     = alltrue([for v in values(var.aws_account_parameters) : contains(["prod", "nonprod", "staging"], v.lifecycle)])
  error_message = "Account lifecycle must be 'prod', 'nonprod', or 'staging'."
}
```

### 2. Add Staging OUs

```hcl
organizational_units = {
  # Existing OUs...
  Security               = { lifecycle = "prod" }
  Infrastructure_Prod    = { lifecycle = "prod" }
  Infrastructure_NonProd = { lifecycle = "nonprod" }
  Workloads_Prod         = { lifecycle = "prod" }
  Workloads_NonProd      = { lifecycle = "nonprod" }
  
  # New staging OUs:
  Infrastructure_Staging = { lifecycle = "staging" }
  Workloads_Staging      = { lifecycle = "staging" }
  
  # Other OUs...
  Sandbox                = { lifecycle = "nonprod" }
  Policy_Staging         = { lifecycle = "nonprod" }
  Suspended              = { lifecycle = "nonprod" }
}
```

### 3. Move Accounts to Staging

```hcl
aws_account_parameters = {
  "261500508709" = {
    email        = "staging-network@yourcorp.com"
    lifecycle    = "staging"           # Changed from "nonprod"
    name         = "Staging-Network"
    ou           = "Infrastructure_Staging"  # New OU
    account_type = "network"
  }
}
```

## Account Types

Account types are managed separately in `config/sra-account-types.yaml` and can be extended independently of OUs and lifecycles. See that file for current account type definitions.

## Best Practices

1. **Plan lifecycle hierarchy** - Consider how your lifecycles relate (dev → staging → prod)
2. **Use consistent naming** - Follow patterns like `{Purpose}_{Lifecycle}` for OUs
3. **Test validation changes** - Run `tofu validate` after updating validation rules
4. **Document custom lifecycles** - Add comments explaining non-standard lifecycle phases
5. **Consider SSO implications** - New lifecycles may need corresponding permission sets

## Migration Strategy

When adding new lifecycles to existing deployments:

1. **Add validation rules first** - Update both validation blocks
2. **Plan the change** - Run `tofu plan` to see what will be created
3. **Apply incrementally** - Consider creating OUs before moving accounts
4. **Update documentation** - Keep this guide and your terraform.tfvars comments current

## Troubleshooting

### Common Issues

- **Validation errors**: Ensure new lifecycle names are added to both validation blocks
- **OU not found**: Verify OU names match exactly (case-sensitive)
- **Account conflicts**: Check that account names remain unique across all OUs

### Validation Commands

```bash
# Validate configuration
tofu validate

# Preview changes
tofu plan

# Check for syntax errors
tofu fmt -check
```

This architecture scales naturally because we eliminated the complex validation rules and tag-based typing that made changes difficult. Now it's just a matter of defining what you want and the module handles the rest!
