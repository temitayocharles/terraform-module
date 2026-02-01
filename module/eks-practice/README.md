# EKS Practice Module

## Purpose
Provision and manage an AWS EKS (Elastic Kubernetes Service) cluster for Kubernetes workloads.

## Input Variables
- `eks_practice_config` (object):
  - See variables.tf for all fields (name, version, subnets, etc.)

## Outputs
- EKS cluster name
- Cluster endpoint

## Usage Example
```hcl
module "eks_practice" {
  source                = "../module/eks-practice"
  eks_practice_config   = var.eks_practice_config
}
```

## Notes
- Supports custom Kubernetes versions and networking.
- See variables.tf for full schema and descriptions.
