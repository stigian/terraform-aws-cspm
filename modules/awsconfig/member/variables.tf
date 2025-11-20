variable "enable_nist_800_171_r2" {
  description = "Whether to deploy the NIST 800-171 Revision 2 conformance pack. This conformance pack helps verify compliance with NIST SP 800-171 Rev 2 requirements for protecting Controlled Unclassified Information (CUI) in non-federal systems."
  type        = bool
  default     = true
}
