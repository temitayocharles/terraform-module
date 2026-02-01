output "provider_arn" {
  value = length(aws_iam_openid_connect_provider.github) > 0 ? aws_iam_openid_connect_provider.github[0].arn : ""
}

output "roles" {
  value = length(aws_iam_role.gha_roles) > 0 ? aws_iam_role.gha_roles[*].arn : []
}
