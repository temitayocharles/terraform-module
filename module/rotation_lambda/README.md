# Rotation Lambda Module

## Purpose
Provision and manage a Lambda function for secret rotation (e.g., RDS password rotation).

## Input Variables
- `rotation_lambda_config` (object):
  - See variables.tf for all fields (enable, name, runtime, etc.)

## Outputs
- Lambda function ARN

## Usage Example
```hcl
module "rotation_lambda" {
  source                   = "../module/rotation_lambda"
  rotation_lambda_config   = var.rotation_lambda_config
}
```

## Notes
- Integrates with RDS and Secrets Manager for automated credential rotation.
- See variables.tf for full schema and descriptions.
