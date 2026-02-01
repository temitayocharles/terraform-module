# RDS Module

## Purpose
Provision and manage an AWS RDS instance with full configuration for engine, networking, security, and credentials.

## Input Variables
- `rds_config` (object):
  - See variables.tf for all fields (engine, version, subnets, security, credentials, etc.)

## Outputs
- RDS instance endpoint
- DB identifier

## Usage Example
```hcl
module "rds" {
  source     = "../module/rds"
  rds_config = var.rds_config
}
```

## Notes
- Use remote state or secrets for sensitive values.
- Supports password rotation via Lambda.
- See variables.tf for full schema and descriptions.
