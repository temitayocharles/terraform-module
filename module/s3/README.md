# S3 Module

## Purpose
Provision and manage AWS S3 buckets for object storage.

## Input Variables
- `s3_config` (object):
  - See variables.tf for all fields (enable, bucket_name, versioning, acl, etc.)

## Outputs
- S3 bucket name
- Bucket ARN

## Usage Example
```hcl
module "s3" {
  source     = "../module/s3"
  s3_config  = var.s3_config
}
```

## Notes
- Supports versioning and force destroy options.
- See variables.tf for full schema and descriptions.
