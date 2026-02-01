output "kms_key_arn" {
  value       = var.kms_secrets_config.enabled ? aws_kms_key.this[0].arn : ""
  description = "KMS key ARN"
}

output "secrets_manager_arn" {
  value       = var.kms_secrets_config.enabled ? aws_secretsmanager_secret.this[0].arn : ""
  description = "Secrets Manager secret ARN"
}

