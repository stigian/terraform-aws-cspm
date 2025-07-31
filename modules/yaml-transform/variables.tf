variable "config_directory" {
  description = "Path to directory containing YAML configuration files"
  type        = string
  # No default - must be explicitly provided for advanced configurations
}

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
  description = "Tags applied to all resources created by this module. These will be merged with YAML-defined tags."
  type        = map(string)
  default = {
    ManagedBy = "opentofu"
    Module    = "terraform-aws-cspm"
  }
}

variable "enable_validation" {
  description = "Enable enhanced validation of YAML configuration data"
  type        = bool
  default     = true
}

variable "control_tower_enabled" {
  description = "Whether Control Tower will be deployed. Affects OU management strategy."
  type        = bool
  default     = true
}
