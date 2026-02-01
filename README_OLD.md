# musicvibe-terraform

## Overview

This repository implements a fully modular, YAML-driven Terraform architecture for AWS. All modules are configured via a single `environment.yaml` file, using object variables for maximum flexibility and maintainability.

## Key Features
- **YAML-driven configuration:** All module inputs are defined in `resource/environment.yaml`.
- **Reusable modules:** Each AWS resource type is implemented as a reusable module, accepting a single object variable.
- **Conditional creation:** Modules are enabled/disabled via the `modules` block in the YAML config.
- **No .tfvars:** All configuration is centralized in YAML; `.tfvars` files are deprecated.
- **Cluster support:** Includes a reusable `ec2-cluster` module for master/worker patterns (Jenkins, Kubernetes, etc.).

## Getting Started

1. Copy and edit `resource/environment.yaml` to match your environment and requirements.
2. (Optional) Review `resource/ec2_cluster_config.example.yaml` for a sample EC2 cluster config.
3. Run `terraform init` and `terraform apply` from the `resource/` directory.

## Example: EC2 Cluster Module

Add the following to your `resource/environment.yaml`:

```yaml
ec2_cluster_config:
  enabled: true
  master_count: 1
  worker_count: 2
  ami: "ami-0360c520857e3138f"
  master_instance_type: "t3.medium"
  worker_instance_type: "t3.medium"
  key_name: "k8s-pipeline-key"
  subnet_id: "subnet-xxxx"
  vpc_security_group_ids:
    - "sg-xxxx"
  iam_instance_profile: "ultimate-cicd-devops-profile"
  master_user_data: "${file(../scripts/jenkins-k8s-master-setup.sh)}"
  worker_user_data: "${file(../scripts/k8s-worker-setup.sh)}"
  tags:
    Project: "ultimate-cicd-devops"
    Environment: "dev"
```

## Usage

In `resource/main.tf`:

```hcl
module "ec2_cluster" {
  count               = lookup(local.env_modules, "ec2_cluster", false) ? 1 : 0
  source              = "../module/ec2-cluster"
  ec2_cluster_config  = local.env.ec2_cluster_config
}
```

## Outputs
- `ec2_cluster_master_ids`, `ec2_cluster_master_public_ips`
- `ec2_cluster_worker_ids`, `ec2_cluster_worker_public_ips`

## Migration Notes
- Legacy `jenkins_k8s_master` and `k8s_worker` modules are now replaced by the unified `ec2-cluster` module.
- All module variables must be objects; no defaults are set in module variable declarations.
- All configuration is YAML-driven; do not use `.tfvars` files.

## See Also
- `module/ec2-cluster/README.md` for detailed schema and usage.
- `resource/ec2_cluster_config.example.yaml` for a sample config block.

---

_Last updated: 2025-12-27_
