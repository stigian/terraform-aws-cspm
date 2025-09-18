data "aws_partition" "current" {}

resource "aws_iam_role" "this" {
  provider    = aws.member
  name        = "AWSControlTowerExecution"
  description = "Allows full account access for Control Tower"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${var.management_account_id}:root"
        }
        Condition = {}
      },
    ]
  })

  tags = var.global_tags
}

data "aws_iam_policy" "this" {
  provider = aws.member
  name     = "AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "this" {
  provider   = aws.member
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.this.arn
}
