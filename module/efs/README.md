# EFS Module

## Purpose
Provision and manage an AWS Elastic File System (EFS) for shared storage across multiple EC2 instances or services.

## Input Variables
- `efs_config` (object):
  - `enabled` (bool): Set to true to enable EFS creation.
  - `subnet_ids` (list(string)): List of subnet IDs for EFS mount targets.

## Outputs
- EFS ID
- Mount target IDs

## Usage Example
```hcl
module "efs" {
  source     = "../module/efs"
  efs_config = var.efs_config
}
```

## Notes
- Subnets should be private and within the same VPC as your compute resources.
- See variables.tf for full schema and descriptions.
