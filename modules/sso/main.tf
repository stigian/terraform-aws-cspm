data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

###############################################################################
# IAM Identity Store
###############################################################################

# TODO: add conditional to join var.security_groups.default list with additional groups
#       the caller may provide.

data "aws_ssoadmin_instances" "this" {
  count = var.use_self_managed_sso ? 1 : 0
}

resource "aws_identitystore_group" "this" {
  for_each          = var.use_self_managed_sso ? local.aws_sso_groups : {}
  display_name      = each.value.display_name
  description       = each.value.description
  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = var.use_self_managed_sso ? { for idx, assignment in local.sso_group_assignments : "${assignment.account_id}-${assignment.group_name}" => assignment } : {}

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.group_name].arn

  principal_id   = aws_identitystore_group.this[each.value.group_name].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}

# Permission sets mapping to personas and compliant framework roles
resource "aws_ssoadmin_permission_set" "this" {
  for_each         = var.use_self_managed_sso ? local.aws_sso_groups : {}
  name             = each.value.display_name
  description      = each.value.description
  instance_arn     = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each           = var.use_self_managed_sso ? local.aws_sso_groups : {}
  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  managed_policy_arn = each.value.managed_policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
}

# Attach AmazonDetectiveFullAccess to aws_admin permission set for Detective console/API access
resource "aws_ssoadmin_managed_policy_attachment" "detective_fullaccess" {
  for_each           = var.use_self_managed_sso && contains(keys(local.aws_sso_groups), "aws_admin") ? { aws_admin = local.aws_sso_groups["aws_admin"] } : {}
  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  managed_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonDetectiveFullAccess"
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
}