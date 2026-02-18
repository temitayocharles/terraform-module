locals {
  env = yamldecode(file("${path.module}/../../resource/environment.yaml"))

  configs = {
    ec2_cluster     = try(local.env.ec2_cluster_config, null)
    nexus_sonarqube = try(local.env.nexus_sonarqube_config, null)
    monitoring      = try(local.env.monitoring_config, null)
    ecs_fargate     = try(local.env.ecs_fargate_config, null)
    eks             = try(local.env.eks_config, null)
    alb             = try(local.env.alb_config, null)
    autoscaling     = try(local.env.autoscaling_config, null)
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

module "ec2_cluster" {
  count              = local.configs.ec2_cluster != null && local.configs.ec2_cluster.enabled ? 1 : 0
  source             = "../../module/ec2-cluster"
  ec2_cluster_config = local.configs.ec2_cluster
}

module "nexus_sonarqube" {
  count               = local.configs.nexus_sonarqube != null ? 1 : 0
  source              = "../../module/ec2-instance"
  ec2_instance_config = local.configs.nexus_sonarqube
}

module "monitoring_instance" {
  count               = local.configs.monitoring != null ? 1 : 0
  source              = "../../module/ec2-instance"
  ec2_instance_config = local.configs.monitoring
}

module "ecs_fargate" {
  count              = local.configs.ecs_fargate != null && local.configs.ecs_fargate.enabled ? 1 : 0
  source             = "../../module/ecs-fargate"
  ecs_fargate_config = local.configs.ecs_fargate
}

module "eks" {
  count               = local.configs.eks != null && local.configs.eks.enabled ? 1 : 0
  source              = "../../module/eks-practice"
  eks_practice_config = local.configs.eks
}

module "alb" {
  count      = local.configs.alb != null && local.configs.alb.enabled ? 1 : 0
  source     = "../../module/alb"
  alb_config = local.configs.alb
}

module "autoscaling" {
  count              = local.configs.autoscaling != null && local.configs.autoscaling.enabled ? 1 : 0
  source             = "../../module/autoscaling"
  autoscaling_config = local.configs.autoscaling
}

output "ec2_cluster_master_ids" {
  value = try(module.ec2_cluster[0].master_instance_ids, [])
}

output "ec2_cluster_worker_ids" {
  value = try(module.ec2_cluster[0].worker_instance_ids, [])
}

output "nexus_sonarqube_instance_ids" {
  value = try(module.nexus_sonarqube[0].instance_ids, [])
}

output "monitoring_instance_ids" {
  value = try(module.monitoring_instance[0].instance_ids, [])
}

output "ecs_cluster_arn" {
  value = try(module.ecs_fargate[0].cluster_arn, "")
}

output "eks_cluster_name" {
  value = try(module.eks[0].cluster_name, "")
}

output "eks_cluster_endpoint" {
  value = try(module.eks[0].cluster_endpoint, "")
}

output "alb_dns_name" {
  value = try(module.alb[0].alb_dns_name, "")
}

output "alb_target_group_arn" {
  value = try(module.alb[0].target_group_arn, "")
}

output "asg_name" {
  value = try(module.autoscaling[0].asg_name, "")
}
