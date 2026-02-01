# ECS Fargate Module

## Purpose
Provision and manage an AWS ECS Fargate service for running containerized workloads.

## Input Variables
- `ecs_fargate_config` (object):
  - See variables.tf for all fields (image, CPU, memory, networking, etc.)

## Outputs
- ECS service name
- Task definition ARN

## Usage Example
```hcl
module "ecs_fargate" {
  source              = "../module/ecs-fargate"
  ecs_fargate_config  = var.ecs_fargate_config
}
```

## Notes
- Integrates with ALB/NLB if configured.
- See variables.tf for full schema and descriptions.
