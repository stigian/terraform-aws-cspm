# output "account_ids" {
#   value = data.aws_organizations_organization.management.accounts[*].id
# }

output "central_bucket_kms_key_arn" {
  value = aws_kms_key.central_log_bucket.arn
}

output "central_bucket_arn" {
  value = module.central_bucket.s3_bucket_arn
}
