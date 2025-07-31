terraform {
  required_version = ">= 1.9.0" # OpenTofu version
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

# Default provider, implicitly passed to all modules
provider "aws" {
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"
}

# Cross-account providers for Control Tower execution roles
provider "aws" {
  alias = "log_archive"
  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${module.yaml_transform.log_archive_account_id}:role/OrganizationAccountAccessRole"
  }
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"
}

provider "aws" {
  alias = "audit"
  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${module.yaml_transform.audit_account_id}:role/OrganizationAccountAccessRole"
  }
  region  = var.aws_region
  profile = "cnscca-gov-mgmt"
}

