# VPC Module

## Purpose
Provision and manage an AWS Virtual Private Cloud (VPC) with configurable CIDR, subnets, and project/environment tagging.

## Input Variables
- `vpc_config` (object):
  - `enabled` (bool): Enable/disable VPC creation.
  - `project_config` (object): Project and environment metadata.
  - `cidr` (string): VPC CIDR block.

## Outputs
- VPC ID
- Subnet IDs

## Usage Example
```hcl
module "vpc" {
  source     = "../module/vpc"
  vpc_config = var.vpc_config
}
```

## Notes
- All subnets and resources are tagged for project and environment.
- See variables.tf for full schema and descriptions.
