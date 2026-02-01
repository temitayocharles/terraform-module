output "log_group_names" {
  value = var.observability_config.enabled ? [for lg in aws_cloudwatch_log_group.this : lg.name] : []
}

output "dashboard_name" {
  value       = var.observability_config.enabled ? aws_cloudwatch_dashboard.this[0].dashboard_name : ""
  description = "CloudWatch dashboard name"
}

