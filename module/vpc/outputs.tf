output "vpc_id" {
  description = "Placeholder VPC id (implement in module)"
  value       = var.vpc_config.enabled ? (aws_vpc.this[0].id) : ""
}

output "subnet_ids" {
  description = "Placeholder subnet ids"
  value       = var.vpc_config.enabled ? aws_subnet.public[*].id : []
}
