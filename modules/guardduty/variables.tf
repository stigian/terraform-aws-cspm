variable "audit_account_id" {
  type        = string
  description = "AWS account ID that will serve as the GuardDuty organization administrator (delegated admin)"
}

variable "cross_account_role_name" {
  type        = string
  description = "Name of the role to assume in the audit account for GuardDuty management"
  default     = "OrganizationAccountAccessRole"
}

variable "global_tags" {
  type        = map(string)
  description = "Global tags to apply to all GuardDuty resources"
  default     = {}
}

# Protection Plan Configuration Variables
# Priority 1 - Recommended for DISA SCCA (default: enabled)
variable "enable_s3_protection" {
  type        = bool
  description = "Enable S3 Protection to monitor S3 data events for suspicious access patterns"
  default     = true
}

variable "enable_runtime_monitoring" {
  type        = bool
  description = "Enable Runtime Monitoring for EC2, EKS, and ECS workloads using eBPF-based agents. See docs/README.md for agent deployment prerequisites."
  default     = true
}

variable "enable_malware_protection_ec2" {
  type        = bool
  description = "Enable Malware Protection for EC2 to scan EBS volumes when suspicious activity is detected. Note: Most enterprise customers use dedicated EDR solutions (Defender, CrowdStrike, etc.)"
  default     = false
}

# Priority 2 - Conditional recommendations (default: disabled)
variable "enable_lambda_protection" {
  type        = bool
  description = "Enable Lambda Protection to monitor VPC Flow Logs for Lambda network activity"
  default     = false
}

variable "enable_eks_protection" {
  type        = bool
  description = "Enable EKS Protection to monitor Kubernetes audit logs (only if using EKS clusters)"
  default     = false
}

variable "enable_rds_protection" {
  type        = bool
  description = "Enable RDS Protection to monitor Aurora database login activity for anomalies"
  default     = false
}

# Priority 3 - Specialized use cases (default: disabled)
variable "enable_malware_protection_s3" {
  type        = bool
  description = "Enable S3 Malware Protection for specific untrusted buckets (not organization-wide)"
  default     = false
}

variable "malware_protection_s3_buckets" {
  type        = list(string)
  description = "List of S3 bucket names to enable malware protection (only used if enable_malware_protection_s3 is true)"
  default     = []
}
