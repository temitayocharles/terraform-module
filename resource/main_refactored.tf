locals {
  env = yamldecode(file("${path.module}/environment.yaml"))
  
  backend_config     = local.env.terraform_backend
  aws_config         = local.env.aws_config
  modules_enabled    = local.env.modules_enabled
  remote_state_config = local.env.remote_state
}

provider "aws" {
  region = local.aws_config.region
}

data "terraform_remote_state" "vpc" {
  count = local.modules_enabled.vpc_state ? 1 : 0
  backend = "s3"
  config = {
    bucket         = local.remote_state_config.vpc.bucket
    key            = local.remote_state_config.vpc.key
    region         = local.remote_state_config.vpc.region
    encrypt        = try(local.remote_state_config.vpc.encrypt, true)
    dynamodb_table = try(local.remote_state_config.vpc.dynamodb_table, "")
  }
}

data "terraform_remote_state" "iam" {
  count = local.modules_enabled.iam_state ? 1 : 0
  backend = "s3"
  config = {
    bucket         = local.remote_state_config.iam.bucket
    key            = local.remote_state_config.iam.key
    region         = local.remote_state_config.iam.region
    encrypt        = try(local.remote_state_config.iam.encrypt, true)
    dynamodb_table = try(local.remote_state_config.iam.dynamodb_table, "")
  }
}

module "oidc" {
  count       = local.modules_enabled.oidc ? 1 : 0
  source      = "../module/oidc"
  oidc_config = local.env.oidc_config
}

module "iam" {
  count       = local.modules_enabled.iam ? 1 : 0
  source      = "../module/iam"
  iam_config  = local.env.iam_config
}

module "vpc" {
  count      = local.modules_enabled.vpc ? 1 : 0
  source     = "../module/vpc"
  vpc_config = local.env.vpc_config
}

module "jenkins_sg" {
  count             = local.modules_enabled.jenkins_sg ? 1 : 0
  source            = "../module/sg-dynamic"
  sg_dynamic_config = local.env.jenkins_sg_config
}

module "k8s_master_sg" {
  count             = local.modules_enabled.k8s_master_sg ? 1 : 0
  source            = "../module/sg-dynamic"
  sg_dynamic_config = local.env.k8s_master_sg_config
}

module "k8s_worker_sg" {
  count             = local.modules_enabled.k8s_worker_sg ? 1 : 0
  source            = "../module/sg-dynamic"
  sg_dynamic_config = local.env.k8s_worker_sg_config
}

module "tools_sg" {
  count             = local.modules_enabled.tools_sg ? 1 : 0
  source            = "../module/sg-dynamic"
  sg_dynamic_config = local.env.tools_sg_config
}

module "monitoring_sg" {
  count             = local.modules_enabled.monitoring_sg ? 1 : 0
  source            = "../module/sg-dynamic"
  sg_dynamic_config = local.env.monitoring_sg_config
}

module "ec2_cluster" {
  count              = local.modules_enabled.ec2_cluster ? 1 : 0
  source             = "../module/ec2-cluster"
  ec2_cluster_config = local.env.ec2_cluster_config
}

module "nexus_sonarqube" {
  count               = local.modules_enabled.nexus_sonarqube ? 1 : 0
  source              = "../module/ec2-instance"
  ec2_instance_config = local.env.nexus_sonarqube_config
}

module "monitoring" {
  count               = local.modules_enabled.monitoring ? 1 : 0
  source              = "../module/ec2-instance"
  ec2_instance_config = local.env.monitoring_config
}

module "ecs_fargate" {
  count              = local.modules_enabled.ecs_fargate ? 1 : 0
  source             = "../module/ecs-fargate"
  ecs_fargate_config = local.env.ecs_fargate_config
}

module "eks" {
  count              = local.modules_enabled.eks ? 1 : 0
  source             = "../module/eks-practice"
  eks_practice_config = local.env.eks_config
}

module "alb" {
  count         = local.modules_enabled.alb ? 1 : 0
  source        = "../module/alb"
  alb_config    = local.env.alb_config
}

module "autoscaling" {
  count                = local.modules_enabled.autoscaling ? 1 : 0
  source               = "../module/autoscaling"
  autoscaling_config   = local.env.autoscaling_config
}

module "rds" {
  count      = local.modules_enabled.rds ? 1 : 0
  source     = "../module/rds"
  rds_config = local.env.rds_config
}

module "rotation_lambda" {
  count                    = local.modules_enabled.rotation_lambda ? 1 : 0
  source                   = "../module/rotation_lambda"
  rotation_lambda_config   = local.env.rotation_lambda_config
}

module "s3" {
  count     = local.modules_enabled.s3 ? 1 : 0
  source    = "../module/s3"
  s3_config = local.env.s3_config
}

module "kms" {
  count               = local.modules_enabled.kms ? 1 : 0
  source              = "../module/kms_secrets"
  kms_secrets_config  = local.env.kms_config
}

module "observability" {
  count                   = local.modules_enabled.observability ? 1 : 0
  source                  = "../module/observability"
  observability_config    = local.env.observability_config
}

module "route53_acm" {
  count                   = local.modules_enabled.route53_acm ? 1 : 0
  source                  = "../module/route53_acm"
  route53_acm_config      = local.env.route53_acm_config
}

module "efs" {
  count     = local.modules_enabled.efs ? 1 : 0
  source    = "../module/efs"
  efs_config = local.env.efs_config
}

module "ecr" {
  count     = local.modules_enabled.ecr ? 1 : 0
  source    = "../module/ecr"
  ecr_config = local.env.ecr_config
}
