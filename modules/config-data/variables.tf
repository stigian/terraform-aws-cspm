variable "config_directory" {
  description = "Path to directory containing YAML configuration files"
  type        = string
  default     = "${path.root}/config"
}

variable "project" {
  description = "Name of the project or application. Used for resource naming and tagging."
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "global_tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}
