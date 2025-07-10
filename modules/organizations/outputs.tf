output "organization_id" {
  description = "The AWS Organization ID."
  value       = aws_organizations_organization.this.id
}

output "organizational_unit_ids" {
  description = "Map of OU names to their AWS Organization Unit IDs."
  value       = { for k, ou in aws_organizations_organizational_unit.this : k => ou.id }
}
