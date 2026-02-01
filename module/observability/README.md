# Observability Module

## Purpose
Provision and manage AWS CloudWatch log groups and related observability resources.

## Input Variables
- `observability_config` (object):
  - See variables.tf for all fields (enable, log_group_prefix, etc.)

## Outputs
- Log group ARNs

## Usage Example
```hcl
module "observability" {
  source                  = "../module/observability"
  observability_config    = var.observability_config
}
```

## Notes
- Use for centralized logging and monitoring.
- See variables.tf for full schema and descriptions.
