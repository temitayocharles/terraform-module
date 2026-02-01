output "certificate_arn" {
  value       = var.route53_acm_config.enabled ? aws_acm_certificate.this[0].arn : ""
  description = "ACM certificate ARN"
}

output "record_name" {
  value       = var.route53_acm_config.enabled ? aws_route53_record.validation[0].name : ""
  description = "Validation record name"
}

