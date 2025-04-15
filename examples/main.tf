module "cspm" {
  source = "../../modules/cspm"
  providers = {
    aws.log         = aws.log
    aws.audit       = aws.audit
    aws.management  = aws.management
    aws.hubandspoke = aws.hubandspoke
  }

  identifier                 = var.identifier
  aws_region                 = var.aws_region
  account_id_map             = var.account_id_map
  aws_organization_id        = var.aws_organization_id
  central_bucket_name_prefix = var.central_bucket_name_prefix
}
