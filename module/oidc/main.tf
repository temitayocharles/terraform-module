locals {
  providers_map = { for p in var.oidc_config.providers_config : p.name => p }
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = length(var.oidc_config.providers_config) > 0 ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = distinct(flatten([for p in var.oidc_config.providers_config : p.audiences]))
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "gha_roles" {
  for_each = { for p in var.oidc_config.providers_config : p.name => p }

  name = each.value.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github[0].arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${each.value.github_org}/${each.value.github_repo}:*"
          }
        }
      }
    ]
  })
}


