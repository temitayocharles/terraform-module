# ECR Module

## Purpose
Provision and manage an AWS Elastic Container Registry (ECR) for storing Docker images.

## Input Variables
- `ecr_config` (object):
  - See variables.tf for all fields (enable, name, etc.)

## Outputs
- ECR repository URL

## Usage Example
```hcl
module "ecr" {
  source      = "../module/ecr"
  ecr_config  = var.ecr_config
}
```

## Notes
- Use for storing and versioning container images.
- See variables.tf for full schema and descriptions.
