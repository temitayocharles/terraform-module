locals {
  env = yamldecode(file("${path.module}/../../resource/environment.yaml"))
  
  configs = {
    s3 = try(local.env.s3_config, null)
    kms = try(local.env.kms_config, null)
    efs = try(local.env.efs_config, null)
    ecr = try(local.env.ecr_config, null)
    observability = try(local.env.observability_config, null)
    route53_acm = try(local.env.route53_acm_config, null)
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

module "s3" {
  count     = local.configs.s3 != null && local.configs.s3.enabled ? 1 : 0
  source    = "../../module/s3"
  s3_config = local.configs.s3
}

module "kms" {
  count              = local.configs.kms != null && local.configs.kms.enabled ? 1 : 0
  source             = "../../module/kms_secrets"
  kms_secrets_config = local.configs.kms
}

module "efs" {
  count      = local.configs.efs != null && local.configs.efs.enabled ? 1 : 0
  source     = "../../module/efs"
  efs_config = local.configs.efs
}

module "ecr" {
  count     = local.configs.ecr != null && local.configs.ecr.enabled ? 1 : 0
  source    = "../../module/ecr"
  ecr_config = local.configs.ecr
}

module "observability" {
  count                = local.configs.observability != null && local.configs.observability.enabled ? 1 : 0
  source               = "../../module/observability"
  observability_config = local.configs.observability
}

module "route53_acm" {
  count              = local.configs.route53_acm != null && local.configs.route53_acm.enabled ? 1 : 0
  source             = "../../module/route53_acm"
  route53_acm_config = local.configs.route53_acm
}

output "s3_bucket_name" {
  value = try(module.s3[0].bucket_name, "")
}

output "kms_key_arn" {
  value = try(module.kms[0].kms_key_arn, "")
}

output "efs_id" {
  value = try(module.efs[0].file_system_id, "")
}

output "ecr_repository_url" {
  value = try(module.ecr[0].repository_url, "")
}

output "cloudwatch_dashboard_url" {
  value = try(module.observability[0].dashboard_url, "")
}

output "acm_certificate_arn" {
  value = try(module.route53_acm[0].certificate_arn, "")
}
