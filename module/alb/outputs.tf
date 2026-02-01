output "alb_arn" {
  value       = var.alb_config.enabled ? aws_lb.this[0].arn : ""
  description = "ALB ARN"
}

output "alb_dns_name" {
  value       = var.alb_config.enabled ? aws_lb.this[0].dns_name : ""
  description = "ALB DNS name"
}

output "target_group_arn" {
  value       = var.alb_config.enabled ? aws_lb_target_group.this[0].arn : ""
  description = "ALB target group ARN"
}
