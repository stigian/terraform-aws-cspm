output "nist_800_171_r2_conformance_pack_arn" {
  description = "ARN of the NIST 800-171 Revision 2 conformance pack (if enabled)"
  value       = var.enable_nist_800_171_r2 ? aws_config_conformance_pack.nist_800_171_r2[0].arn : null
}
