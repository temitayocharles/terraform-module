locals { enabled = var.rotation_lambda_config.enabled }

data "archive_file" "lambda_zip" {
  count       = var.rotation_lambda_config.enabled ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/src/postgres_rotation.py"
  output_path = "${path.module}/src/postgres_rotation.zip"
}

resource "aws_iam_role" "lambda_exec" {
  count = var.rotation_lambda_config.enabled ? 1 : 0
  name  = "${var.rotation_lambda_config.name}-exec"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Principal = { Service = "lambda.amazonaws.com" }, Effect = "Allow" }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  count = var.rotation_lambda_config.enabled ? 1 : 0
  name  = "${var.rotation_lambda_config.name}-policy"
  role  = aws_iam_role.lambda_exec[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  count            = var.rotation_lambda_config.enabled ? 1 : 0
  filename         = data.archive_file.lambda_zip[0].output_path
  function_name    = var.rotation_lambda_config.name
  role             = aws_iam_role.lambda_exec[0].arn
  handler          = var.rotation_lambda_config.handler
  runtime          = var.rotation_lambda_config.runtime
  timeout          = var.rotation_lambda_config.timeout
  memory_size      = var.rotation_lambda_config.memory_size
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip[0].output_path)
}
