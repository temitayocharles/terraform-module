# ALB Module

## Purpose
Provision and manage an AWS Application Load Balancer (ALB) for distributing traffic to EC2 or container services.

## Input Variables
- `alb_config` (object):
  - See variables.tf for all fields (enable, name, subnets, security groups, etc.)

## Outputs
- ALB DNS name
- Target group ARNs

## Usage Example
```hcl
module "alb" {
  source      = "../module/alb"
  alb_config  = var.alb_config
}
```

## Notes
- Integrates with autoscaling and ECS modules.
- See variables.tf for full schema and descriptions.
