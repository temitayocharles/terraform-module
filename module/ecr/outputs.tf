output "repository_url" {
  description = "ECR repository URL (implement)"
  value       = var.ecr_config.enabled ? aws_ecr_repository.this[0].repository_url : ""
}
