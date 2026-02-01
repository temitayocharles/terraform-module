locals {
  env = yamldecode(file("${path.module}/../../resource/environment.yaml"))
  
  configs = {
    rds = try(local.env.rds_config, null)
    rotation_lambda = try(local.env.rotation_lambda_config, null)
  }
}

terraform {
  required_version = ">= 1.0"
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

module "rotation_lambda" {
  count                  = local.configs.rotation_lambda != null && local.configs.rotation_lambda.enabled ? 1 : 0
  source                 = "../../module/rotation_lambda"
  rotation_lambda_config = local.configs.rotation_lambda
}

module "rds" {
  count      = local.configs.rds != null && local.configs.rds.enabled ? 1 : 0
  source     = "../../module/rds"
  rds_config = merge(
    local.configs.rds,
    {
      rotation_lambda_arn = try(module.rotation_lambda[0].lambda_arn, "")
    }
  )
}

output "rds_endpoint" {
  value = try(module.rds[0].endpoint, "")
}

output "rds_instance_id" {
  value = try(module.rds[0].instance_id, "")
}

output "rds_secret_arn" {
  value = try(module.rds[0].secret_arn, "")
}

output "lambda_arn" {
  value = try(module.rotation_lambda[0].lambda_arn, "")
}
