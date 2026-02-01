output "endpoint" {
  value       = var.rds_config.enabled ? aws_db_instance.this[0].endpoint : ""
  description = "RDS instance endpoint (with port)"
}

output "address" {
  value       = var.rds_config.enabled ? aws_db_instance.this[0].address : ""
  description = "RDS instance address"
}

output "instance_id" {
  value       = var.rds_config.enabled ? aws_db_instance.this[0].id : ""
  description = "RDS instance id"
}

output "secret_arn" {
  value       = var.rds_config.enabled && var.rds_config.create_secret ? aws_secretsmanager_secret.this[0].arn : ""
  description = "ARN of the Secrets Manager secret containing DB credentials (if created)"
}

output "security_group_id" {
  value       = var.rds_config.enabled ? (length(local.effective_sg_ids) > 0 ? local.effective_sg_ids[0] : "") : ""
  description = "Security group id used by the RDS instance"
}

output "secret_rotation_enabled" {
  value       = var.rds_config.enabled && var.rds_config.create_secret && var.rds_config.rotation_lambda_arn != "" ? true : false
  description = "If true, Secrets Manager rotation is configured for the created secret"
}

