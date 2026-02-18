locals {
  env = yamldecode(file("${path.module}/../../resource/environment.yaml"))

  enabled = try(local.env.modules_enabled, {})

  sg_config_default = {
    vpc_id                = "vpc-00000000"
    create_before_destroy = false
    config = {
      security_group_name        = "placeholder-sg"
      security_group_description = "placeholder"
      tags                       = {}
      allow_all                  = false
      inbound_rules              = []
      outbound_rules             = []
    }
  }

  sg_configs = {
    jenkins    = try(local.env.jenkins_sg_config, null)
    k8s_master = try(local.env.k8s_master_sg_config, null)
    k8s_worker = try(local.env.k8s_worker_sg_config, null)
    tools      = try(local.env.tools_sg_config, null)
    monitoring = try(local.env.monitoring_sg_config, null)
  }
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

module "jenkins_sg" {
  count             = try(local.enabled.jenkins_sg, false) && local.sg_configs.jenkins != null ? 1 : 0
  source            = "../../module/sg-dynamic"
  sg_dynamic_config = try(local.enabled.jenkins_sg, false) ? local.sg_configs.jenkins : local.sg_config_default
}

module "k8s_master_sg" {
  count             = try(local.enabled.k8s_master_sg, false) && local.sg_configs.k8s_master != null ? 1 : 0
  source            = "../../module/sg-dynamic"
  sg_dynamic_config = try(local.enabled.k8s_master_sg, false) ? local.sg_configs.k8s_master : local.sg_config_default
}

module "k8s_worker_sg" {
  count             = try(local.enabled.k8s_worker_sg, false) && local.sg_configs.k8s_worker != null ? 1 : 0
  source            = "../../module/sg-dynamic"
  sg_dynamic_config = try(local.enabled.k8s_worker_sg, false) ? local.sg_configs.k8s_worker : local.sg_config_default
}

module "tools_sg" {
  count             = try(local.enabled.tools_sg, false) && local.sg_configs.tools != null ? 1 : 0
  source            = "../../module/sg-dynamic"
  sg_dynamic_config = try(local.enabled.tools_sg, false) ? local.sg_configs.tools : local.sg_config_default
}

module "monitoring_sg" {
  count             = try(local.enabled.monitoring_sg, false) && local.sg_configs.monitoring != null ? 1 : 0
  source            = "../../module/sg-dynamic"
  sg_dynamic_config = try(local.enabled.monitoring_sg, false) ? local.sg_configs.monitoring : local.sg_config_default
}

output "jenkins_sg_id" {
  value = try(module.jenkins_sg[0].security_group_id, "")
}

output "k8s_master_sg_id" {
  value = try(module.k8s_master_sg[0].security_group_id, "")
}

output "k8s_worker_sg_id" {
  value = try(module.k8s_worker_sg[0].security_group_id, "")
}

output "tools_sg_id" {
  value = try(module.tools_sg[0].security_group_id, "")
}

output "monitoring_sg_id" {
  value = try(module.monitoring_sg[0].security_group_id, "")
}
