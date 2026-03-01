data "archive_file" "api" {
  type        = "zip"
  source_dir  = "../../endpoints/${local.endpoint_name}"
  output_path = "endpoints/${local.endpoint_name}.zip"
  excludes = [
    "phpunit.xml",
    "phpstan.neon",
    ".env",
    ".env.example",
    "README.md",
    "tests",
    "*.zip",
    ".idea",
    "storage",
    "node_modules",
    ".git"
  ]
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "api" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
    ]

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/${var.api_name}-${local.endpoint_name}-${var.env}:*"
    ]
  }
}