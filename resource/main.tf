locals {
  env = yamldecode(file("${path.module}/environment.yaml"))

  # Prefer remote state outputs when available, else fall back to provided var or local discovery
  final_vpc_id    = length(data.terraform_remote_state.vpc) > 0 && try(data.terraform_remote_state.vpc[0].outputs.vpc_id, "") != "" ? data.terraform_remote_state.vpc[0].outputs.vpc_id : (var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id)
  final_subnet_id = length(data.terraform_remote_state.vpc) > 0 && try(data.terraform_remote_state.vpc[0].outputs.subnet_id, "") != "" ? data.terraform_remote_state.vpc[0].outputs.subnet_id : data.aws_subnet.selected.id

  # safe accessors for optional environment.yaml keys
  env_modules        = lookup(local.env, "modules", {})
  env_remote_state   = lookup(local.env, "remote_state", lookup(lookup(local.env, "feature_flags", {}), "remote_state", {}))
  env_oidc_config    = lookup(local.env, "oidc_config", null)
  env_oidc_providers = lookup(local.env, "oidc_providers", [])
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

# Optional: read VPC outputs from another terraform state (S3 backend)
data "terraform_remote_state" "vpc" {
  # only configure remote_state vpc if bucket/key/region are present
  count = (
    lookup(local.env_remote_state, "vpc", null) != null &&
    lookup(lookup(local.env_remote_state, "vpc", {}), "bucket", "") != "" &&
    lookup(lookup(local.env_remote_state, "vpc", {}), "key", "") != "" &&
    lookup(lookup(local.env_remote_state, "vpc", {}), "region", "") != ""
  ) ? 1 : 0
  backend = "s3"
  config = {
    bucket = lookup(lookup(local.env_remote_state, "vpc", {}), "bucket", "")
    key    = lookup(lookup(local.env_remote_state, "vpc", {}), "key", "")
    region = lookup(lookup(local.env_remote_state, "vpc", {}), "region", "")
  }
}

# Optional: read IAM outputs from another terraform state (S3 backend)
data "terraform_remote_state" "iam" {
  count = (
    lookup(local.env_remote_state, "iam", null) != null &&
    lookup(lookup(local.env_remote_state, "iam", {}), "bucket", "") != "" &&
    lookup(lookup(local.env_remote_state, "iam", {}), "key", "") != "" &&
    lookup(lookup(local.env_remote_state, "iam", {}), "region", "") != ""
  ) ? 1 : 0
  backend = (count.index == 0 ? "s3" : null)
  config = (count.index == 0 ? {
    bucket = lookup(lookup(local.env_remote_state, "iam", {}), "bucket", "")
    key    = lookup(lookup(local.env_remote_state, "iam", {}), "key", "")
    region = lookup(lookup(local.env_remote_state, "iam", {}), "region", "")
  } : null)
}

locals {
  iam_jenkins_profile = length(data.terraform_remote_state.iam) > 0 && try(data.terraform_remote_state.iam[0].outputs.jenkins_instance_profile_name, "") != "" ? data.terraform_remote_state.iam[0].outputs.jenkins_instance_profile_name : (module.iam.jenkins_instance_profile_name != "" ? module.iam.jenkins_instance_profile_name : null)
}

# Create OIDC provider + roles for GitHub Actions based on environment.yaml
module "oidc" {
  count       = (length(local.env_oidc_providers) > 0 && try(local.env_oidc_config["enable_github_oidc"], false)) ? 1 : 0
  source      = "../module/oidc"
  oidc_config = lookup(local.env, "oidc_config", { providers_config = local.env_oidc_providers, region = local.env.aws_config.region })
}

# IAM module: create instance profiles or reuse remote-state outputs
module "iam" {
  source = "../module/iam"
  iam_config = {
    project_config           = local.env.project_config
    enable_instance_profiles = length(data.terraform_remote_state.iam) > 0 ? false : (lookup(local.env, "iam_config", null) != null ? lookup(local.env.iam_config, "enable_instance_profiles", false) : false)
    names                    = lookup(local.env, "iam_names", {})
  }
}


# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the first available subnet
data "aws_subnet" "selected" {
  id = data.aws_subnets.default.ids[0]
}

module "jenkins_sg" {
  count  = lookup(local.env_modules, "jenkins_sg", false) ? 1 : 0
  source = "../module/sg-dynamic"
  sg_dynamic_config = {
    vpc_id                = local.final_vpc_id
    create_before_destroy = false
    config = {
      security_group_name        = "${local.env.project_config.name}-jenkins-sg"
      security_group_description = "Security group for Jenkins server"
      tags = {
        Name        = "${local.env.project_config.name}-jenkins-sg"
        Project     = local.env.project_config.name
        Environment = local.env.project_config.environment
      }
      allow_all = true
      inbound_rules = [
        {
          from_port                 = 22
          to_port                   = 22
          protocol                  = "tcp"
          cidr_blocks               = local.env.ssh_config.allowed_cidr
          source_security_group_ids = []
          description               = "SSH"
        },
        {
          from_port                 = 80
          to_port                   = 80
          protocol                  = "tcp"
          cidr_blocks               = ["0.0.0.0/0"]
          source_security_group_ids = []
          description               = "HTTP"
        },
        {
          from_port                 = 443
          to_port                   = 443
          protocol                  = "tcp"
          cidr_blocks               = ["0.0.0.0/0"]
          source_security_group_ids = []
          description               = "HTTPS"
        },
        {
          from_port                 = 8080
          to_port                   = 8080
          protocol                  = "tcp"
          cidr_blocks               = ["0.0.0.0/0"]
          source_security_group_ids = []
          description               = "Jenkins"
        }
      ]
      outbound_rules = [
        {
          from_port                      = 0
          to_port                        = 0
          protocol                       = "-1"
          cidr_blocks                    = ["0.0.0.0/0"]
          destination_security_group_ids = []
          description                    = "Allow all outbound"
        }
      ]
    }
  }
}

output "jenkins_sg_id" {
  value = length(module.jenkins_sg) > 0 ? module.jenkins_sg[0].security_group_id : ""
}

module "k8s_master_sg" {
  count  = lookup(local.env_modules, "k8s_master_sg", false) ? 1 : 0
  source = "../module/sg-dynamic"
  sg_dynamic_config = {
    vpc_id                = local.final_vpc_id
    create_before_destroy = false
    config = {
      security_group_name        = "${local.env.project_config.name}-k8s-master-sg"
      security_group_description = "Security group for Kubernetes master node"
      tags = {
        Name        = "${local.env.project_config.name}-k8s-master-sg"
        Project     = local.env.project_config.name
        Environment = local.env.project_config.environment
      }
      allow_all = true
      inbound_rules = [
        { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = local.env.ssh_config.allowed_cidr, source_security_group_ids = [], description = "SSH" },
        { from_port = 6443, to_port = 6443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Kubernetes API" },
        { from_port = 2379, to_port = 2380, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "etcd" },
        { from_port = 10250, to_port = 10250, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Kubelet API" },
        { from_port = 10259, to_port = 10259, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "kube-scheduler" },
        { from_port = 10257, to_port = 10257, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "kube-controller-manager" },
        { from_port = 30000, to_port = 32767, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "NodePort Services" },
        { from_port = 179, to_port = 179, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Calico BGP" },
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "HTTP" },
        { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "HTTPS" }
      ]
      outbound_rules = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], destination_security_group_ids = [], description = "Allow all outbound" }
      ]
    }
  }
}

module "k8s_worker_sg" {
  count  = lookup(local.env_modules, "k8s_worker_sg", false) ? 1 : 0
  source = "../module/sg-dynamic"
  sg_dynamic_config = {
    vpc_id                = local.final_vpc_id
    create_before_destroy = false
    config = {
      security_group_name        = "${local.env.project_config.name}-k8s-worker-sg"
      security_group_description = "Security group for Kubernetes worker nodes"
      tags = {
        Name        = "${local.env.project_config.name}-k8s-worker-sg"
        Project     = local.env.project_config.name
        Environment = local.env.project_config.environment
      }
      allow_all = true
      inbound_rules = [
        { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = local.env.ssh_config.allowed_cidr, source_security_group_ids = [], description = "SSH" },
        { from_port = 10250, to_port = 10250, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Kubelet API" },
        { from_port = 30000, to_port = 32767, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "NodePort Services" },
        { from_port = 179, to_port = 179, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Calico BGP" },
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "HTTP" },
        { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "HTTPS" }
      ]
      outbound_rules = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], destination_security_group_ids = [], description = "Allow all outbound" }
      ]
    }
  }
}

module "tools_sg" {
  count  = lookup(local.env_modules, "tools_sg", false) ? 1 : 0
  source = "../module/sg-dynamic"
  sg_dynamic_config = {
    vpc_id                = local.final_vpc_id
    create_before_destroy = false
    config = {
      security_group_name        = "${local.env.project_config.name}-tools-sg"
      security_group_description = "Security group for Nexus and SonarQube"
      tags = {
        Name        = "${local.env.project_config.name}-tools-sg"
        Project     = local.env.project_config.name
        Environment = local.env.project_config.environment
      }
      allow_all = true
      inbound_rules = [
        { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = local.env.ssh_config.allowed_cidr, source_security_group_ids = [], description = "SSH" },
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "HTTP" },
        { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "HTTPS" },
        { from_port = 8081, to_port = 8081, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Nexus" },
        { from_port = 9000, to_port = 9000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "SonarQube" }
      ]
      outbound_rules = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], destination_security_group_ids = [], description = "Allow all outbound" }
      ]
    }
  }
}


module "monitoring_sg" {
  count  = lookup(local.env_modules, "monitoring_sg", false) ? 1 : 0
  source = "../module/sg-dynamic"
  sg_dynamic_config = {
    vpc_id                = local.final_vpc_id
    create_before_destroy = false
    config = {
      security_group_name        = "${local.env.project_config.name}-monitoring-sg"
      security_group_description = "Security group for Prometheus and Grafana"
      tags = {
        Name        = "${local.env.project_config.name}-monitoring-sg"
        Project     = local.env.project_config.name
        Environment = local.env.project_config.environment
      }
      allow_all = true
      inbound_rules = [
        { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = local.env.ssh_config.allowed_cidr, source_security_group_ids = [], description = "SSH" },
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "HTTP" },
        { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "HTTPS" },
        { from_port = 3000, to_port = 3000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Grafana" },
        { from_port = 9090, to_port = 9090, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Prometheus" },
        { from_port = 9100, to_port = 9100, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Node Exporter" },
        { from_port = 9115, to_port = 9115, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], source_security_group_ids = [], description = "Blackbox Exporter" }
      ]
      outbound_rules = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], destination_security_group_ids = [], description = "Allow all outbound" }
      ]
    }
  }
}

output "k8s_master_sg_id" { value = length(module.k8s_master_sg) > 0 ? module.k8s_master_sg[0].security_group_id : "" }
output "k8s_worker_sg_id" { value = length(module.k8s_worker_sg) > 0 ? module.k8s_worker_sg[0].security_group_id : "" }
output "tools_sg_id" { value = length(module.tools_sg) > 0 ? module.tools_sg[0].security_group_id : "" }
output "monitoring_sg_id" { value = length(module.monitoring_sg) > 0 ? module.monitoring_sg[0].security_group_id : "" }

/* EC2 instances converted to module calls */


# New unified EC2 cluster module (masters/workers)
module "ec2_cluster" {
  count  = lookup(local.env_modules, "ec2_cluster", false) ? 1 : 0
  source = "../module/ec2-cluster"
  ec2_cluster_config = merge(
    local.env.ec2_cluster_config,
    {
      vpc_security_group_ids = concat(
        length(module.k8s_master_sg) > 0 ? [module.k8s_master_sg[0].security_group_id] : [],
        length(module.k8s_worker_sg) > 0 ? [module.k8s_worker_sg[0].security_group_id] : []
      )
    }
  )
}

module "nexus_sonarqube" {
  count  = lookup(local.env_modules, "nexus_sonarqube", false) ? 1 : 0
  source = "../module/ec2-instance"
  ec2_instance_config = {
    instance_count         = 1
    ami                    = local.env.ami_config.id
    instance_type          = local.env.instance_types.master
    key_name               = local.env.ssh_config.key_name
    subnet_id              = local.final_subnet_id
    vpc_security_group_ids = [for id in [length(module.tools_sg) > 0 ? module.tools_sg[0].security_group_id : null] : id if id != null]
    iam_instance_profile   = local.iam_jenkins_profile
    root_block_device      = { volume_size = 30, volume_type = "gp3" }
    user_data              = file("../scripts/nexus-sonarqube-setup.sh")
    tags                   = { Name = "${local.env.project_config.name}-nexus-sonarqube", Project = local.env.project_config.name, Environment = local.env.project_config.environment, Role = "Tools-Server" }
  }
}

module "monitoring" {
  count  = lookup(local.env_modules, "monitoring", false) ? 1 : 0
  source = "../module/ec2-instance"
  ec2_instance_config = {
    instance_count         = 1
    ami                    = local.env.ami_config.id
    instance_type          = local.env.instance_types.monitoring
    key_name               = local.env.ssh_config.key_name
    subnet_id              = local.final_subnet_id
    vpc_security_group_ids = [for id in [length(module.monitoring_sg) > 0 ? module.monitoring_sg[0].security_group_id : null] : id if id != null]
    iam_instance_profile   = local.iam_jenkins_profile
    root_block_device      = { volume_size = 20, volume_type = "gp3" }
    user_data              = file("../scripts/monitoring-setup.sh")
    tags                   = { Name = "${local.env.project_config.name}-monitoring", Project = local.env.project_config.name, Environment = local.env.project_config.environment, Role = "Monitoring" }
  }
}


# EC2 cluster outputs
output "ec2_cluster_master_ids" {
  value = length(module.ec2_cluster) > 0 ? module.ec2_cluster[0].master_instance_ids : []
}
output "ec2_cluster_worker_ids" {
  value = length(module.ec2_cluster) > 0 ? module.ec2_cluster[0].worker_instance_ids : []
}
output "nexus_sonarqube_ids" { value = flatten([for m in module.nexus_sonarqube : m.instance_ids]) }
output "monitoring_ids" { value = flatten([for m in module.monitoring : m.instance_ids]) }

output "oidc_roles" { value = length(module.oidc) > 0 ? module.oidc[0].roles : {} }

module "ecs_fargate_practice" {
  count  = lookup(local.env_modules, "ecs_fargate", false) ? 1 : 0
  source = "../module/ecs-fargate"
  ecs_fargate_config = {
    enabled            = true
    name               = "${local.env.project_config.name}-ecs-practice"
    subnet_ids         = [local.final_subnet_id]
    security_group_ids = length(module.tools_sg) > 0 ? [module.tools_sg[0].security_group_id] : []
    container_image    = lookup(local.env, "ecs_image", "nginx:stable-alpine")
    cpu                = lookup(local.env, "ecs_cpu", 256)
    memory             = lookup(local.env, "ecs_memory", 512)
    desired_count      = lookup(local.env, "ecs_desired_count", 1)
    target_group_arn   = length(module.alb) > 0 ? module.alb[0].target_group_arn : ""
    container_port     = lookup(local.env, "ecs_container_port", 80)
  }
}

module "eks_practice" {
  count  = lookup(local.env_modules, "eks_practice", false) ? 1 : 0
  source = "../module/eks-practice"
  eks_practice_config = {
    enabled         = true
    name            = "${local.env.project_config.name}-eks-practice"
    subnet_ids      = [local.final_subnet_id]
    cluster_version = "1.27" # TODO: update as needed
  }
  # version attribute removed for local module source
}

output "ecs_fargate_cluster_arn" { value = length(module.ecs_fargate_practice) > 0 ? module.ecs_fargate_practice[0].cluster_arn : "" }
output "ecs_fargate_service_name" { value = length(module.ecs_fargate_practice) > 0 ? module.ecs_fargate_practice[0].service_name : "" }
output "eks_practice_name" { value = length(module.eks_practice) > 0 ? module.eks_practice[0].cluster_name : "" }
output "eks_practice_endpoint" { value = length(module.eks_practice) > 0 ? module.eks_practice[0].cluster_endpoint : "" }


output "ec2_cluster_master_public_ips" {
  value = length(module.ec2_cluster) > 0 ? module.ec2_cluster[0].master_public_ips : []
}
output "ec2_cluster_worker_public_ips" {
  value = length(module.ec2_cluster) > 0 ? module.ec2_cluster[0].worker_public_ips : []
}

output "nexus_sonarqube_public_ip" {
  value = length(module.nexus_sonarqube) > 0 && length(module.nexus_sonarqube[0].public_ips) > 0 ? module.nexus_sonarqube[0].public_ips[0] : "Not created"
}

output "monitoring_public_ip" {
  value = length(module.monitoring) > 0 && length(module.monitoring[0].public_ips) > 0 ? module.monitoring[0].public_ips[0] : "Not created"
}


output "jenkins_url" {
  value = length(module.ec2_cluster) > 0 && length(module.ec2_cluster[0].master_public_ips) > 0 ? "http://${module.ec2_cluster[0].master_public_ips[0]}:8080" : "Not created"
}

output "nexus_url" {
  value = length(module.nexus_sonarqube) > 0 && length(module.nexus_sonarqube[0].public_ips) > 0 ? "http://${module.nexus_sonarqube[0].public_ips[0]}:8081" : "Not created"
}

output "sonarqube_url" {
  value = length(module.nexus_sonarqube) > 0 && length(module.nexus_sonarqube[0].public_ips) > 0 ? "http://${module.nexus_sonarqube[0].public_ips[0]}:9000" : "Not created"
}

output "grafana_url" {
  value = length(module.monitoring) > 0 && length(module.monitoring[0].public_ips) > 0 ? "http://${module.monitoring[0].public_ips[0]}:3000" : "Not created"
}

output "prometheus_url" {
  value = length(module.monitoring) > 0 && length(module.monitoring[0].public_ips) > 0 ? "http://${module.monitoring[0].public_ips[0]}:9090" : "Not created"
}


output "ssh_commands" {
  value = {
    ec2_cluster_masters = length(module.ec2_cluster) > 0 && length(module.ec2_cluster[0].master_public_ips) > 0 ? [for ip in module.ec2_cluster[0].master_public_ips : "ssh -i ${local.env.ssh_config.key_name}.pem ubuntu@${ip}"] : []
    ec2_cluster_workers = length(module.ec2_cluster) > 0 && length(module.ec2_cluster[0].worker_public_ips) > 0 ? [for ip in module.ec2_cluster[0].worker_public_ips : "ssh -i ${local.env.ssh_config.key_name}.pem ubuntu@${ip}"] : []
    nexus_sonarqube    = length(module.nexus_sonarqube) > 0 && length(module.nexus_sonarqube[0].public_ips) > 0 ? "ssh -i ${local.env.ssh_config.key_name}.pem ubuntu@${module.nexus_sonarqube[0].public_ips[0]}" : "Not created"
    monitoring         = length(module.monitoring) > 0 && length(module.monitoring[0].public_ips) > 0 ? "ssh -i ${local.env.ssh_config.key_name}.pem ubuntu@${module.monitoring[0].public_ips[0]}" : "Not created"
  }
}

/* Additional scaffolded modules */

module "vpc_module" {
  count  = lookup(local.env_modules, "vpc", false) ? 1 : 0
  source = "../module/vpc"
  vpc_config = {
    enabled        = true
    project_config = local.env.project_config
    cidr           = "10.0.0.0/16"
  }
}

module "ecr" {
  count  = lookup(local.env_modules, "ecr", false) ? 1 : 0
  source = "../module/ecr"
  ecr_config = {
    enabled = true
    name    = "${local.env.project_config.name}-ecr"
  }
}

module "alb" {
  count  = lookup(local.env_modules, "alb", false) ? 1 : 0
  source = "../module/alb"
  alb_config = {
    enabled             = true
    name                = "${local.env.project_config.name}-alb"
    vpc_id              = local.final_vpc_id
    subnet_ids          = [local.final_subnet_id]
    security_group_ids  = length(module.tools_sg) > 0 ? [module.tools_sg[0].security_group_id] : []
    health_check_path   = lookup(local.env, "alb_health_check_path", "/")
    port                = lookup(local.env, "alb_port", 80)
    target_instance_ids = length(module.ec2_cluster) > 0 ? concat(module.ec2_cluster[0].master_instance_ids, module.ec2_cluster[0].worker_instance_ids) : []
  }
}

module "autoscaling" {
  count  = lookup(local.env_modules, "autoscaling", false) ? 1 : 0
  source = "../module/autoscaling"
  autoscaling_config = {
    enabled              = true
    name                 = "${local.env.project_config.name}-asg"
    ami                  = local.env.ami_config.id
    instance_type        = local.env.instance_types.worker
    subnet_ids           = [local.final_subnet_id]
    security_group_ids   = length(module.k8s_worker_sg) > 0 ? [module.k8s_worker_sg[0].security_group_id] : []
    key_name             = local.env.ssh_config.key_name
    user_data            = lookup(local.env, "asg_user_data", file("../scripts/k8s-worker-setup.sh"))
    iam_instance_profile = local.iam_jenkins_profile != null ? local.iam_jenkins_profile : ""
    target_group_arns    = length(module.alb) > 0 ? [module.alb[0].target_group_arn] : []
    create_iam_profile   = false
    min_size             = lookup(local.env, "asg_min_size", 1)
    max_size             = lookup(local.env, "asg_max_size", 3)
    desired_capacity     = lookup(local.env, "asg_desired_capacity", 2)
  }
}

module "rds" {
  count  = lookup(local.env_modules, "rds", false) ? 1 : 0
  source = "../module/rds"
  rds_config = {
    enabled                           = true
    engine                            = lookup(local.env.rds_config, "engine", "postgres")
    engine_version                    = lookup(local.env.rds_config, "engine_version", "13")
    instance_class                    = lookup(local.env.rds_config, "instance_class", "db.t3.micro")
    allocated_storage                 = lookup(local.env.rds_config, "allocated_storage", 20)
    subnet_ids                        = [local.final_subnet_id]
    security_group_ids                = length(module.tools_sg) > 0 ? [module.tools_sg[0].security_group_id] : []
    allowed_source_cidr               = lookup(local.env.rds_config, "allowed_source_cidr", [])
    allowed_source_security_group_ids = length(module.k8s_master_sg) > 0 ? [module.k8s_master_sg[0].security_group_id] : []
    rotation_lambda_arn               = length(module.rotation_lambda) > 0 ? module.rotation_lambda[0].lambda_arn : ""
    rotation_days                     = lookup(local.env.rds_config, "rotation_days", 30)
    vpc_id                            = local.final_vpc_id
    require_vpc_for_sg                = true
    username                          = lookup(local.env.rds_config, "username", "dbadmin")
    password                          = lookup(local.env.rds_config, "password", "changeme")
    create_secret                     = lookup(local.env.rds_config, "create_secret", true)
    secret_name                       = lookup(local.env.rds_config, "secret_name", "${local.env.project_config.name}-rds-secret")
    db_name                           = lookup(local.env.rds_config, "db_name", "appdb")
    skip_final_snapshot               = lookup(local.env.rds_config, "skip_final_snapshot", true)
  }
}

module "rotation_lambda" {
  count  = lookup(local.env_modules, "rotation_lambda", false) ? 1 : 0
  source = "../module/rotation_lambda"
  rotation_lambda_config = {
    enabled     = true
    name        = "${local.env.project_config.name}-rds-rotation"
    runtime     = "python3.9" # TODO: update as needed
    handler     = "postgres_rotation.lambda_handler" # TODO: update as needed
    timeout     = 30 # TODO: update as needed
    memory_size = 128 # TODO: update as needed
  }
}

/* rotation lambda instantiated above; its ARN is passed into the RDS module */

module "s3_bucket" {
  count  = lookup(local.env_modules, "s3", false) ? 1 : 0
  source = "../module/s3"
  s3_config = {
    enabled     = true
    bucket_name = "${local.env.project_config.name}-${local.env.project_config.environment}-bucket"
    versioning  = false # TODO: update as needed
  }
}

module "kms_secrets" {
  count  = lookup(local.env_modules, "kms_secrets", false) ? 1 : 0
  source = "../module/kms_secrets"
  kms_secrets_config = {
    enabled = true
    name    = "${local.env.project_config.name}-kms"
  }
}

module "observability" {
  count  = lookup(local.env_modules, "observability", false) ? 1 : 0
  source = "../module/observability"
  observability_config = {
    enabled          = true
    log_group_prefix = local.env.project_config.name
  }
}

module "route53_acm" {
  count  = lookup(local.env_modules, "route53_acm", false) ? 1 : 0
  source = "../module/route53_acm"
  route53_acm_config = {
    enabled        = true
    domain_name    = ""
    hosted_zone_id = ""
  }
}

module "efs" {
  count  = lookup(local.env_modules, "efs", false) ? 1 : 0
  source = "../module/efs"
  efs_config = {
    enabled    = true
    subnet_ids = [local.final_subnet_id]
  }
}

output "vpc_id" { value = length(module.vpc_module) > 0 ? module.vpc_module[0].vpc_id : "" }
output "ecr_repository_url" { value = length(module.ecr) > 0 ? module.ecr[0].repository_url : "" }
output "alb_dns" { value = length(module.alb) > 0 ? module.alb[0].alb_dns_name : "" }
output "asg_name" { value = length(module.autoscaling) > 0 ? module.autoscaling[0].asg_name : "" }
output "rds_endpoint" { value = length(module.rds) > 0 ? module.rds[0].endpoint : "" }
output "app_bucket" { value = length(module.s3_bucket) > 0 ? module.s3_bucket[0].bucket_name : "" }
output "kms_key_arn" { value = length(module.kms_secrets) > 0 ? module.kms_secrets[0].kms_key_arn : "" }
output "observability_dashboard" { value = length(module.observability) > 0 ? module.observability[0].dashboard_url : "" }
output "acm_certificate_arn" { value = length(module.route53_acm) > 0 ? module.route53_acm[0].certificate_arn : "" }
output "efs_id" { value = length(module.efs) > 0 ? module.efs[0].file_system_id : "" }
