variable "project" {
  description = "Name of the project or application. Used for naming resources."
  type        = string
  default     = "demo"
}

variable "tags" {
  description = "A map of tags to add to all resources. These are merged with any resource-specific tags."
  type        = map(string)
  default = {
    Project    = "demo"
    Owner      = "stigian"
    Repository = "https://github.com/stigian/terraform-aws-cspm"
  }
}

variable "aws_organization_id" {
  description = "ID for existing AWS Govcloud Organization. If not provided, the module will create a new organization."
  type        = string
  default     = null
}

variable "organizational_units" {
  description = <<-EOT
    Map of Organizational Unit (OU) names to their attributes.

    Example:
      {
        Security = {
          lifecycle = "prod"
          tags      = { Owner = "SecurityTeam" }
        }
        Workloads_Prod = {
          lifecycle = "prod"
          tags      = {}
        }
      }

    - The key is the OU name.
    - The value is an object with:
        - lifecycle: (string) The lifecycle tag for the OU (e.g., "prod", "test").
        - tags:      (optional map) Additional tags for the OU.
  EOT
  type = map(object({
    lifecycle = string
    tags      = optional(map(string), {})
  }))
  default = {
    Security = {
      lifecycle = "prod"
      tags      = {}
    }
    Infrastructure_Prod = {
      lifecycle = "prod"
      tags      = {}
    }
    Infrastructure_Test = {
      lifecycle = "nonprod"
      tags      = {}
    }
    Workloads_Prod = {
      lifecycle = "prod"
      tags      = {}
    }
    Workloads_Test = {
      lifecycle = "nonprod"
      tags      = {}
    }
    Sandbox = {
      lifecycle = "nonprod"
      tags      = {}
    }
    Policy_Staging = {
      lifecycle = "nonprod"
      tags      = {}
    }
    Suspended = {
      lifecycle = "nonprod"
      tags      = {}
    }
  }

  validation {
    condition     = alltrue([for k in keys(var.organizational_units) : length(trimspace(k)) > 0])
    error_message = "OU names (keys) must not be empty."
  }

  validation {
    condition     = alltrue([for v in values(var.organizational_units) : length(trimspace(v.lifecycle)) > 0])
    error_message = "Each OU must have a non-empty 'lifecycle' value."
  }

  validation {
    condition     = alltrue([for v in values(var.organizational_units) : contains(["prod", "nonprod", "test", "dev", "staging"], v.lifecycle)])
    error_message = "Each OU 'lifecycle' must be one of: 'prod', 'nonprod', 'test', 'dev', or 'staging'."
  }
}

variable "aws_account_parameters" {
  description = <<-EOT
    Map of AWS account parameters to be managed by the module.

    - Each key is an AWS account ID (12-digit string).
    - Each value is an object with:
        - email:      The email address for the AWS account.
                      For existing GovCloud accounts, this must match the current email shown in the AWS Console.
        - lifecycle:  The lifecycle tag for the account (e.g., "prod", "nonprod").
        - name:       The display name for the account.
                      For existing GovCloud accounts, this must match the current account name shown in the AWS Console.
        - ou:         The Organizational Unit (OU) name to assign the account to.
                      Must match one of the OUs defined in 'organizational_units'.
        - tags:       (Optional) Additional tags to apply to the account.

    Example:
      {
        "111111111111" = {
          email     = "account1@example.com"
          lifecycle = "prod"
          name      = "Management"
          ou        = "Security"
          tags      = {
            Environment = "Production"
            Team        = "DevOps"
          }
        }
      }

    Notes:
      - For existing GovCloud accounts, the 'name' and 'email' values must match what is currently set in the AWS Console. These values cannot be changed from GovCloud; updates must be made from the commercial (linked) account.
      - The 'ou' value must correspond to an OU created by the module.
  EOT
  type = map(object({
    email     = string
    lifecycle = string
    name      = string
    ou        = string
    tags      = optional(map(string), {})
  }))
}
