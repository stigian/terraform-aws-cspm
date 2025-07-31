variable "project" {
  description = "Name of the project or application. Used for resource naming and tagging."
  type        = string
  default     = "CnScca"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project))
    error_message = "Project name must contain only letters, numbers, and hyphens."
  }
}

variable "global_tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default = {
    ManagedBy = "opentofu"
  }
}

variable "control_tower_enabled" {
  description = <<-EOT
    Whether Control Tower will be deployed with this organization.

    **IMPORTANT: This significantly changes OU management behavior:**

    When true (Control Tower mode):
    - Organizations module will NOT create "Security" and "Sandbox" OUs
    - Control Tower landing zone will create and manage these OUs instead
    - Accounts targeting Control Tower-managed OUs are temporarily placed at Root
    - Control Tower will move them to proper OUs during landing zone deployment
    - Enforces Control Tower account requirements (management, log_archive, audit accounts)
    - Validates AccountType tags and specific OU placements

    When false (Organizations-only mode):
    - Organizations module creates ALL OUs defined in organizational_units
    - No Control Tower integration or constraints
    - AccountType tags are optional
    - More flexible OU assignments allowed

    **Control Tower-managed OUs:** Security, Sandbox
    **Organizations-managed OUs:** Infrastructure_Prod, Infrastructure_NonProd, Workloads_Prod, Workloads_NonProd, Policy_Staging, Suspended
  EOT
  type        = bool
  default     = true
}

variable "aws_organization_id" {
  description = "ID for existing AWS Govcloud Organization. If not provided, the module will create a new organization."
  type        = string
  default     = null
}

variable "organizational_units" {
  description = <<-EOT
    Map of Organizational Unit (OU) names to their attributes.
    
    Uses AWS Security Reference Architecture (SRA) standard OUs by default:
    - Security: For audit, log archive, and security tooling accounts
    - Infrastructure_Prod/NonProd: For network and shared services accounts  
    - Workloads_Prod/NonProd: For application workload accounts
    - Sandbox: For experimentation and development
    - Policy_Staging: For testing organizational policies
    - Suspended: For decommissioned accounts

    **CONTROL TOWER INTEGRATION:**
    When control_tower_enabled = true:
    - "Security" and "Sandbox" OUs are NOT created by this module
    - Control Tower landing zone creates and manages these OUs
    - Only the remaining OUs are created by the organizations module
    - Accounts targeting Control Tower OUs are placed at Root initially, then moved by Control Tower

    When control_tower_enabled = false:
    - ALL OUs defined here are created by the organizations module
    - Standard organizational structure with no Control Tower constraints

    Example:
      {
        Security = {
          lifecycle = "prod"
          tags      = { Owner = "SecurityTeam" }
        }
      }
  EOT
  type = map(object({
    lifecycle = optional(string, "prod") # Default to prod
    tags      = optional(map(string), {})
  }))

  # Provide SRA-standard defaults - users can override entirely if needed
  default = {
    Security               = { lifecycle = "prod" }
    Infrastructure_Prod    = { lifecycle = "prod" }
    Infrastructure_NonProd = { lifecycle = "nonprod" }
    Workloads_Prod         = { lifecycle = "prod" }
    Workloads_NonProd      = { lifecycle = "nonprod" }
    Sandbox                = { lifecycle = "nonprod" }
    Policy_Staging         = { lifecycle = "nonprod" }
    Suspended              = { lifecycle = "nonprod" }
  }

  # Simplified validation - just check lifecycle values are valid
  validation {
    condition     = alltrue([for v in values(var.organizational_units) : contains(["prod", "nonprod"], v.lifecycle)])
    error_message = "OU lifecycle must be 'prod' or 'nonprod'."
  }
}

variable "aws_account_parameters" {
  description = <<-EOT
    Map of AWS account parameters to be managed by the module.

    PREREQUISITE: All accounts must already exist (created via AWS Organizations CLI).

    Structure:
      {
        "123456789012" = {
          name         = "YourCorp-Management"
          email        = "aws-mgmt@yourcorp.com"
          ou           = "Root"
          lifecycle    = "prod"
          account_type = "management"
        }
      }

    **CONTROL TOWER ACCOUNT PLACEMENT:**
    When control_tower_enabled = true:
    - Accounts with ou = "Security" or ou = "Sandbox" are placed at "Root" initially
    - Control Tower landing zone will move them to the proper Control Tower-managed OUs
    - Other accounts are placed in organizations-managed OUs normally
    - Required account types: management, log_archive, audit (see validation below)

    When control_tower_enabled = false:
    - All accounts are placed in their specified OUs directly
    - No Control Tower constraints or account type requirements

    See config/account-schema.yaml for detailed field definitions and examples.
    See config/sra-account-types.yaml for valid account_type values.
  EOT
  type = map(object({
    name            = string
    email           = string
    ou              = string
    lifecycle       = string
    account_type    = optional(string, "")
    create_govcloud = optional(bool, false)
  }))

  # Core validation - keep it simple
  validation {
    condition     = alltrue([for k in keys(var.aws_account_parameters) : can(regex("^[0-9]{12}$", k))])
    error_message = "Account IDs must be exactly 12 digits."
  }

  validation {
    condition     = alltrue([for v in values(var.aws_account_parameters) : can(regex("^\\S+@\\S+\\.\\S+$", v.email))])
    error_message = "Each account must have a valid email address."
  }

  validation {
    condition     = length(values(var.aws_account_parameters)[*].name) == length(distinct(values(var.aws_account_parameters)[*].name))
    error_message = "Account names must be unique."
  }

  validation {
    condition     = alltrue([for v in values(var.aws_account_parameters) : contains(["prod", "nonprod"], v.lifecycle)])
    error_message = "Account lifecycle must be 'prod' or 'nonprod'."
  }

  # Control Tower validation - only when enabled
  validation {
    condition = !var.control_tower_enabled || alltrue([
      # When Control Tower is enabled, only require management account in Organizations module
      # audit and log_archive accounts are managed directly by Control Tower
      length([for v in values(var.aws_account_parameters) : v if v.account_type == "management"]) >= 1,
    ])
    error_message = "When Control Tower is enabled, Organizations module requires at least a management account. Audit and log_archive accounts are managed by Control Tower module."
  }
}
