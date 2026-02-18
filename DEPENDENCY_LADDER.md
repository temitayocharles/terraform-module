# Dependency Ladder

    ## Repository
    - [`terraform-module`](https://github.com/temitayocharles/terraform-module)
    - Role: **Layer 1 - Infrastructure Foundation (Reusable Modules)**

    ## Upstream Dependencies
    - None

    ## Downstream Consumers
    - [`infra-environments`](https://github.com/temitayocharles/infra-environments)

    ## Canonical Ladder (Portfolio)
    - [`configurations`](https://github.com/temitayocharles/configurations)
- [`shared-workflows`](https://github.com/temitayocharles/shared-workflows)
- [`utilities-scripts`](https://github.com/temitayocharles/utilities-scripts)
- [`vault-ops`](https://github.com/temitayocharles/vault-ops)
- [`helm-charts`](https://github.com/temitayocharles/helm-charts)
- [`platform-gitops`](https://github.com/temitayocharles/platform-gitops)
- [`infra-environments`](https://github.com/temitayocharles/infra-environments)
- [`terraform-module`](https://github.com/temitayocharles/terraform-module)
- [`cila-health-monolith`](https://github.com/temitayocharles/cila-health-monolith)
- [`cila-health-microservices`](https://github.com/temitayocharles/cila-health-microservices)
- [`cila-health-infrastructure-gitops`](https://github.com/temitayocharles/cila-health-infrastructure-gitops)
- [`fintech-gitops`](https://github.com/temitayocharles/fintech-gitops)

    ## Blast Radius Guidance
    - Changes here should be reviewed for impact on downstream repos before merge.
    - For deploy-impacting changes, require validation in CI and in GitOps dry-run paths where applicable.

    ## Cross-Links
    - [`ARCHITECTURE.md`](./ARCHITECTURE.md)
    - [`START_HERE.md`](./START_HERE.md)
