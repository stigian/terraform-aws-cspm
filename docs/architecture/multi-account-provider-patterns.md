# Multi-Account Provider Patterns for AWS Organizations

## Overview

This document outlines patterns for using a single management account provider in the root module while enabling submodules to access member accounts via role chaining through `OrganizationAccountAccessRole`.

## Current State

We currently use a simplified single provider approach:

```hcl
# Root module - examples/main.tf
provider "aws" {
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"  # Management account credentials
}

module "organizations" {
  source = "../modules/organizations"
  # Uses default provider (management account)
}
```

## Pattern 1: Module-Level Role Chaining (Recommended)

### Use Case
When you need a submodule to manage resources in specific member accounts while keeping the root module simple.

### Implementation

#### Submodule Structure
```hcl
# modules/member-account-config/versions.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
      configuration_aliases = [
        aws,              # Default (management account)
        aws.member,       # For member account access
      ]
    }
  }
}

# modules/member-account-config/main.tf
# Management account operations (Organizations API, etc.)
data "aws_organizations_account" "target" {
  # Runs in management account context via default provider
}

# Member account operations
resource "aws_iam_role" "workload_role" {
  provider = aws.member
  # Runs in member account context via role assumption
  name = "WorkloadRole"
  # ...
}
```

#### Root Module Usage
```hcl
# Root module - examples/main.tf
provider "aws" {
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"
}

# Define aliased providers for member accounts
provider "aws" {
  alias   = "logging_account"
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"
  
  assume_role {
    role_arn = "arn:aws-us-gov:iam::${var.logging_account_id}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "audit_account"
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"
  
  assume_role {
    role_arn = "arn:aws-us-gov:iam::${var.audit_account_id}:role/OrganizationAccountAccessRole"
  }
}

module "member_account_config" {
  source = "../modules/member-account-config"
  
  providers = {
    aws        = aws                  # Management account (default)
    aws.member = aws.logging_account  # Member account via role chaining
  }
}
```

## Pattern 2: Dynamic Role Assumption

### Use Case
When you need to dynamically configure multiple member accounts without predefining all provider aliases.

### Implementation

#### Helper Module for Role Assumption
```hcl
# modules/account-access/main.tf
variable "target_account_id" {
  description = "Account ID to assume role in"
  type        = string
}

variable "aws_partition" {
  description = "AWS partition (aws or aws-us-gov)"
  type        = string
  default     = "aws-us-gov"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# Configure provider for target account
provider "aws" {
  alias  = "target"
  region = var.aws_region
  
  assume_role {
    role_arn = "arn:${var.aws_partition}:iam::${var.target_account_id}:role/OrganizationAccountAccessRole"
  }
}

# Resources that operate in the member account
resource "aws_iam_role" "member_specific_role" {
  provider = aws.target
  name     = "MemberAccountRole-${var.target_account_id}"
  # ...
}
```

#### Usage with for_each
```hcl
# Root module
module "configure_member_accounts" {
  for_each = var.member_account_ids
  source   = "../modules/account-access"
  
  target_account_id = each.value
  aws_partition     = data.aws_partition.current.partition
  aws_region        = var.aws_region
}
```

## Pattern 3: Provider Factory Pattern

### Use Case
When you need maximum flexibility and want to generate providers programmatically.

### Implementation

```hcl
# locals.tf
locals {
  # Generate provider configurations for all member accounts
  member_accounts = {
    for account_id, account_config in var.aws_account_parameters :
    account_id => {
      name             = account_config.name
      role_arn         = "arn:${data.aws_partition.current.partition}:iam::${account_id}:role/OrganizationAccountAccessRole"
      account_type     = lookup(account_config.tags, "AccountType", "unknown")
    }
    if account_config.ou != "Root"  # Skip management account
  }
}

# This pattern requires OpenTofu 1.6+ and dynamic provider configuration
```

## Integration Points with Current Architecture

### Organizations Module
- **Keep as-is**: Single provider, manages Organizations resources
- **Future enhancement**: Add optional `aws.member` provider alias for account-level configurations

### SSO Module
- **Current**: Single provider for Identity Center (management account)
- **Future enhancement**: Could use member account providers for account-specific IAM configurations

### Future CSPM Module
- **Ideal candidate**: Use Pattern 1 to deploy security tooling in each member account
- **Management account**: Configure organizational policies, delegated administration
- **Member accounts**: Deploy GuardDuty detectors, Security Hub, Config rules

## Implementation Roadmap

### Phase 1 (Current)
- ✅ Single provider pattern working
- ✅ Organizations module simplified
- ✅ SSO module functional

### Phase 2 (Next)
- [ ] Create example submodule using Pattern 1
- [ ] Test role chaining with actual AWS accounts
- [ ] Document provider alias naming conventions

### Phase 3 (Future)
- [ ] Implement CSPM module with multi-account pattern
- [ ] Create helper modules for common cross-account operations
- [ ] Add validation for OrganizationAccountAccessRole existence

## Best Practices

### Provider Alias Naming
```hcl
# Use descriptive aliases based on account purpose
aws.management  # Management account (usually default)
aws.logging     # Log archive account
aws.audit       # Audit/security account
aws.network     # Network hub account
aws.workload_prod  # Production workload accounts
aws.workload_dev   # Development workload accounts
```

### Role ARN Construction
```hcl
# Always use partition-aware ARN construction
"arn:${data.aws_partition.current.partition}:iam::${account_id}:role/OrganizationAccountAccessRole"

# For GovCloud: arn:aws-us-gov:iam::123456789012:role/OrganizationAccountAccessRole
# For Commercial: arn:aws:iam::123456789012:role/OrganizationAccountAccessRole
```

### Error Handling
```hcl
# Check if OrganizationAccountAccessRole exists before assuming
data "aws_iam_role" "org_access_role" {
  provider = aws.management
  name     = "OrganizationAccountAccessRole"
  
  # This data source will fail if role doesn't exist
  # Consider using try() function for graceful handling
}
```

## Notes for Future Implementation

1. **Testing**: Create integration tests that validate role assumption works across all account types
2. **Documentation**: Update module READMEs with provider requirements when role chaining is added
3. **Examples**: Create working examples for each pattern
4. **Validation**: Add validation rules to ensure required roles exist in member accounts
5. **Regional Considerations**: Handle multi-region deployments with consistent role assumption

## Questions to Address Later

- Should we standardize on one pattern or support multiple?
- How do we handle member accounts that don't have OrganizationAccountAccessRole?
- Do we need a helper module to validate cross-account access before attempting operations?
- How do we handle provider configuration for modules that might be used in different contexts?
