locals {
  env = yamldecode(file("${path.module}/../../resource/environment.yaml"))
  config = local.env.vpc_config
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

module "vpc" {
  source     = "../../module/vpc"
  vpc_config = local.config
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = try(module.vpc.subnet_ids, [])
}

output "availability_zones" {
  value = try(module.vpc.availability_zones, [])
}
