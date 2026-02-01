# Autoscaling Module

## Purpose
Provision and manage an AWS Auto Scaling Group (ASG) for EC2 instances with full configuration for scaling, networking, and IAM.

## Input Variables
- `autoscaling_config` (object):
  - See variables.tf for all fields (instance type, subnets, scaling, IAM, etc.)

## Outputs
- ASG name
- Instance IDs

## Usage Example
```hcl
module "autoscaling" {
  source              = "../module/autoscaling"
  autoscaling_config  = var.autoscaling_config
}
```

## Notes
- Integrates with ALB/NLB via target group ARNs.
- See variables.tf for full schema and descriptions.
