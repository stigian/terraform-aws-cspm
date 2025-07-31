# Control Tower Integration

This guide explains how the terraform-aws-cspm module integrates with AWS Control Tower and manages the OU structure during Control Tower landing zone deployment.

## Overview

When `control_tower_enabled = true`, the module implements a **hybrid OU management strategy** where some OUs are managed by the organizations module and others are managed by Control Tower.

## OU Management Strategy

### Control Tower-Managed OUs
Control Tower landing zone creates and manages these OUs:
- **Security** - For audit and log archive accounts
- **Sandbox** - For experimentation accounts

### Organizations Module-Managed OUs  
The organizations module creates and manages these OUs:
- **Infrastructure_Prod** / **Infrastructure_NonProd** - Network and shared services
- **Workloads_Prod** / **Workloads_NonProd** - Application workloads
- **Policy_Staging** - Policy testing
- **Suspended** - Decommissioned accounts

## Account Placement Behavior

### During Organizations Module Deployment

When `control_tower_enabled = true`:

1. **Organizations-managed OUs are created** (Infrastructure, Workloads, etc.)
2. **Control Tower OUs are NOT created** (Security, Sandbox)
3. **Accounts targeting organizations OUs** are placed normally
4. **Accounts targeting Control Tower OUs** are placed at Root temporarily

### During Control Tower Landing Zone Deployment

When Control Tower landing zone is deployed:

1. **Control Tower creates Security and Sandbox OUs**
2. **Control Tower moves accounts from Root to proper OUs**:
   - log_archive account → Security OU
   - audit account → Security OU
   - Any accounts configured for Sandbox → Sandbox OU

### Example Account Placement

```hcl
aws_account_parameters = {
  "227234344980" = {
    name         = "Management"
    email        = "mgmt@company.com"
    ou           = "Root"              # Stays at Root (management account)
    account_type = "management"
  }
  "261503748007" = {
    name         = "Log Archive"
    email        = "logs@company.com"
    ou           = "Security"          # Temporarily at Root → moved to Security by Control Tower
    account_type = "log_archive"
  }
  "261523644253" = {
    name         = "Audit"
    email        = "audit@company.com"
    ou           = "Security"          # Temporarily at Root → moved to Security by Control Tower
    account_type = "audit"
  }
  "261632763096" = {
    name         = "Workload"
    email        = "app@company.com"
    ou           = "Workloads_NonProd" # Placed directly by organizations module
    account_type = "workload"
  }
}
```

## Architecture Benefits

### Clean Separation of Concerns
- **Organizations module**: Focuses on standard OU structure and account management
- **Control Tower module**: Handles Control Tower-specific requirements and landing zone
- **yaml-transform module**: Coordinates between modules and handles complex logic

### No Resource Conflicts
- Organizations module won't try to create OUs that Control Tower will create
- No competing resource management between modules
- Clean handoff of account placement responsibilities

### Flexible Deployment Options
- `control_tower_enabled = false`: Pure organizations management
- `control_tower_enabled = true`: Hybrid organizations + Control Tower management

## Configuration Guidelines

### Required Account Types for Control Tower
When `control_tower_enabled = true`, you must have:
- At least 1 account with `account_type = "management"`
- At least 1 account with `account_type = "log_archive"`  
- At least 1 account with `account_type = "audit"`

### OU Target Guidelines
- **Management account**: Always use `ou = "Root"`
- **Log archive account**: Use `ou = "Security"` (Control Tower will handle placement)
- **Audit account**: Use `ou = "Security"` (Control Tower will handle placement)
- **Other accounts**: Use any OU name (organizations or Control Tower managed)

## Troubleshooting

### "OU already exists" Errors
If you see errors about Security or Sandbox OUs already existing:
1. Check that `control_tower_enabled = true` 
2. Verify the yaml-transform module is properly excluding Control Tower OUs
3. Ensure organizations module is using `organizations_managed_ous` not full `organizational_units`

### Accounts in Wrong OUs
If accounts end up in the wrong OUs after deployment:
1. **During organizations deployment**: Accounts targeting Control Tower OUs should be at Root
2. **After Control Tower deployment**: Control Tower should move them to proper OUs
3. Check Control Tower landing zone deployment logs for placement issues

### Missing OUs
If expected OUs are missing:
1. **Control Tower OUs missing**: Check Control Tower landing zone deployment status
2. **Organizations OUs missing**: Check `organizations_managed_ous` output from yaml-transform
3. **All OUs missing**: Verify `control_tower_enabled` setting matches your deployment strategy

## Module Integration

This integration pattern is implemented through:
- **yaml-transform module**: `ou_placement_config` and `organizations_managed_ous` outputs
- **organizations module**: Conditional OU creation based on `control_tower_enabled`
- **controltower module**: Landing zone manifest with OU definitions

See the individual module documentation for implementation details.
