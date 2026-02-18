locals {
  env        = yamldecode(file("${path.module}/../../resource/environment.yaml"))
  iam_config = local.env.iam_config
  oidc_config = try({
    providers_config = try(local.env.oidc_config.providers_config, [])
    region           = local.env.aws_config.region
  }, null)
}

terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.env.aws_config.region
}

module "iam" {
  source     = "../../module/iam"
  iam_config = local.iam_config
}

module "oidc" {
  count       = local.oidc_config != null && length(local.oidc_config.providers_config) > 0 ? 1 : 0
  source      = "../../module/oidc"
  oidc_config = local.oidc_config
}

output "jenkins_instance_profile_name" {
  value = try(module.iam.jenkins_instance_profile_name, "")
}

output "oidc_roles" {
  value = try(module.oidc[0].roles, {})
}
