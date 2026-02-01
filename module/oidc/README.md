# OIDC Module

## Purpose
Provision and manage AWS OIDC providers for GitHub Actions or other federated identity integrations.

## Input Variables
- `oidc_config` (object):
  - See variables.tf for all fields (providers_config, region, etc.)

## Outputs
- OIDC provider ARNs

## Usage Example
```hcl
module "oidc" {
  source        = "../module/oidc"
  oidc_config   = var.oidc_config
}
```

## Notes
- Supports multiple providers and audiences.
- See variables.tf for full schema and descriptions.
