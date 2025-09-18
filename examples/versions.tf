terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    random = {
      source  = "random"
      version = ">= 3.1.0"
    }
  }
}

# ── shared local values (once, at the top) ──
locals {
  non_lz_accounts    = local.non_lz_accounts_map
  non_mgmt_accounts  = local.non_mgmt_accounts_map
  all_accounts       = local.aws_account_parameters
}

# ── provider configurations ──
# 1. default / management
provider "aws" {
  region = var.aws_region
}

# 2. explicit management alias (same credentials, different alias)
provider "aws" {
  alias  = "management"
  region = var.aws_region
}

# 3. log-archive account
provider "aws" {
  alias  = "log_archive"
  region = var.aws_region
  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.log_archive_account_id}:role/OrganizationAccountAccessRole"
  }
}

# 4. audit account
provider "aws" {
  alias  = "audit"
  region = var.aws_region
  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.audit_account_id}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  for_each = local.non_lz_accounts_map
  alias    = "org_exec"
  region   = var.aws_region
  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${each.key}:role/${var.org_exec_role_name}"
  }
}

provider "aws" {
  for_each = local.non_mgmt_accounts_map
  alias    = "ct_exec"
  region   = var.aws_region
  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${each.key}:role/AWSControlTowerExecution"
  }
}
