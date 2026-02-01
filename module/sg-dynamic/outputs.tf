output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.this.id
}

output "rule_ids" {
  description = "Map of generated security group rule resource IDs"
  value = {
    rules       = { for k, r in aws_security_group_rule.rules : k => r.id }
    egress_dest = { for k, r in aws_security_group_rule.egress_dest_rules : k => r.id }
  }
}
