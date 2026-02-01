output "file_system_id" {
  value       = var.efs_config.enabled ? aws_efs_file_system.this[0].id : ""
  description = "EFS file system id"
}

