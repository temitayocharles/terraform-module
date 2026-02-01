# KMS & Secrets Module

## Purpose
Provision and manage AWS KMS keys and Secrets Manager secrets for secure storage and encryption.

## Input Variables
- `kms_secrets_config` (object):
  - See variables.tf for all fields (enable, name, etc.)

## Outputs
- KMS key ARN
- Secret ARN

## Usage Example
```hcl
module "kms_secrets" {
  source               = "../module/kms_secrets"
  kms_secrets_config   = var.kms_secrets_config
}
```

## Notes
- Use for encrypting sensitive data and managing secrets.
- See variables.tf for full schema and descriptions.
