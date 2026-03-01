locals {
  env = yamldecode(file("${path.module}/../../resource/environment.yaml"))
}

terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

provider "aws" {
  region = local.env.aws_config.region
}

locals {
  cluster_name = try(local.env.argocd_bootstrap_config.cluster_name, local.env.eks_config.name)
}

data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

module "argocd_bootstrap" {
  count = try(local.env.modules_enabled.argocd_bootstrap, false) ? 1 : 0

  source = "../../module/argocd-bootstrap"

  argocd_bootstrap_config = local.env.argocd_bootstrap_config
  repo_passwords          = {}
}
