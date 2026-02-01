output "master_instance_ids" {
  description = "IDs of master instances"
  value       = aws_instance.master[*].id
}

output "master_public_ips" {
  description = "Public IPs of master instances"
  value       = aws_instance.master[*].public_ip
}

output "worker_instance_ids" {
  description = "IDs of worker instances"
  value       = aws_instance.worker[*].id
}

output "worker_public_ips" {
  description = "Public IPs of worker instances"
  value       = aws_instance.worker[*].public_ip
}
