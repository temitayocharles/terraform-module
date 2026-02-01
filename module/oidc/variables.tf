variable "oidc_config" {
  description = <<DESC
OIDC providers and region configuration.

providers_config: List of OIDC provider objects for GitHub Actions integration. Each object should include:
  - name: Name for the OIDC provider (user-defined, used for resource naming and tagging)
  - github_org: GitHub organization name
  - github_repo: GitHub repository name
  - audiences: List of audiences for the OIDC provider (defaults to ['sts.amazonaws.com'])

region: AWS region for OIDC resources (e.g., 'us-east-1').
DESC
  type = object({
    providers_config = list(object({
      name        = string
      github_org  = string
      github_repo = string
      audiences   = optional(list(string), ["sts.amazonaws.com"])
    }))
    region = string
  })
}
