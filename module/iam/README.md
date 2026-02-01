# IAM Module

## Purpose
Provision and manage AWS IAM roles, instance profiles, and policies for secure access control.

## Input Variables
- `iam_config` (object):
  - See variables.tf for all fields (project, enable_instance_profiles, names, etc.)

## Outputs
- IAM role ARNs
- Instance profile names

## Usage Example
```hcl
module "iam" {
  source      = "../module/iam"
  iam_config  = var.iam_config
}
```

## Notes
- Use for managing access to AWS resources for EC2 and services.
- See variables.tf for full schema and descriptions.
