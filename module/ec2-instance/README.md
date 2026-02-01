# EC2 Instance Module

## Purpose
Provision and manage a single EC2 instance or a small group with full configuration for networking, IAM, and storage.

## Input Variables
- `ec2_instance_config` (object):
  - See variables.tf for all fields (AMI, type, networking, tags, etc.)

## Outputs
- Instance ID(s)
- Public/private IP(s)

## Usage Example
```hcl
module "ec2_instance" {
  source                = "../module/ec2-instance"
  ec2_instance_config   = var.ec2_instance_config
}
```

## Notes
- Supports custom user data and root block device configuration.
- See variables.tf for full schema and descriptions.
