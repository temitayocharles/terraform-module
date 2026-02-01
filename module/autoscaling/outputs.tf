
output "asg_name" {
    value       = var.autoscaling_config.enabled ? aws_autoscaling_group.this[0].name : ""
  description = "AutoScaling Group name when enabled"
}

output "launch_template_id" {
  value       = var.autoscaling_config.enabled ? aws_launch_template.this[0].id : ""
  description = "Launch Template id"
}

output "asg_arn" {
  value       = var.autoscaling_config.enabled ? aws_autoscaling_group.this[0].arn : ""
  description = "AutoScaling Group ARN"
}

output "instance_profile_name" {
  value       = var.autoscaling_config.enabled && var.autoscaling_config.create_iam_profile ? aws_iam_instance_profile.this[0].name : var.autoscaling_config.iam_instance_profile
  description = "Instance profile name used by the launch template"
}

