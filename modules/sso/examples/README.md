# Example: SSO with Organizations Module Integration

This example shows how to use the SSO module together with the Organizations module.

## Prerequisites

- AWS Organizations already set up
- Required AWS accounts already created
- Appropriate AWS permissions for Identity Center management

## Files

- `main.tf` - Main configuration combining organizations and SSO modules
- `variables.tf` - Input variables
- `outputs.tf` - Module outputs
- `versions.tf` - Provider requirements

## Usage

1. Copy these files to your project
2. Update `terraform.tfvars` with your specific values
3. Run:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

## Configuration

The example demonstrates:
- Setting up AWS Organizations with OUs
- Configuring AWS SSO with persona-based groups
- Optional Entra ID integration
- Proper variable passing between modules
