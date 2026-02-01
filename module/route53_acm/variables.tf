variable "route53_acm_config" {
  description = <<DESC
Route53 and ACM configuration object.

enabled: Set to true to enable creation of Route53 and ACM resources. If false, no resources will be created.
domain_name: Domain name to register or validate (e.g., 'example.com').
hosted_zone_id: Hosted zone ID for the domain. Can be auto-populated from remote state or set manually.
github_org: GitHub organization for OIDC integration (if used).
github_repo: GitHub repository for OIDC integration (if used).
audiences: List of audiences for OIDC provider (usually includes 'sts.amazonaws.com').
DESC
  type = object({
    enabled        = bool
    domain_name    = string
    hosted_zone_id = string
    github_org     = string
    github_repo    = string
    audiences      = list(string)
  })
}
