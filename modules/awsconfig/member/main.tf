resource "aws_config_conformance_pack" "nist_800_53_r5" {
  provider      = aws.member
  name          = "cnscca-nist-800-53-r5"
  template_body = file("${path.module}/templates/Operational-Best-Practices-for-NIST-800-53-rev-5.yaml")
}
