# Route53/ACM Module

## Purpose
Provision and manage AWS Route53 hosted zones and ACM certificates for domain management and SSL.

## Input Variables
- `route53_acm_config` (object):
  - See variables.tf for all fields (enable, domain_name, hosted_zone_id, etc.)

## Outputs
- Hosted zone ID
- ACM certificate ARN

## Usage Example
```hcl
module "route53_acm" {
  source                = "../module/route53_acm"
  route53_acm_config    = var.route53_acm_config
}
```

## Notes
- Integrates with OIDC for domain validation if needed.
- See variables.tf for full schema and descriptions.
