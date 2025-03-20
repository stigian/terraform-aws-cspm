terraform {
  required_version = ">= 1.8.0" # OpenTofu version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
      configuration_aliases = [
        aws.log,
        aws.audit,
        aws.management,
        aws.hubandspoke,
      ]
    }
    random = {
      source  = "random"
      version = ">= 3.1.0"
    }
  }
}

