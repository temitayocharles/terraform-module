output "lambda_arn" {
  value       = var.rotation_lambda_config.enabled ? aws_lambda_function.this[0].arn : ""
  description = "ARN of the starter rotation lambda"
}

output "lambda_name" {
  value       = var.rotation_lambda_config.enabled ? aws_lambda_function.this[0].function_name : ""
  description = "Name of the starter rotation lambda"
}
