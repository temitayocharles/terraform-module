# Terraform Module Repository

Modular AWS infrastructure with stack-by-stack deployment support.

## Start Here
- [`START_HERE.md`](./START_HERE.md)
- [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md)
- [`resource/environment.yaml.template`](./resource/environment.yaml.template)

## Repository Layout
```text
module/      Reusable Terraform modules
stacks/      Stack entrypoints (vpc, iam, security, compute, bootstrap, database, storage)
resource/    Combined/legacy root deployment
scripts/     Bootstrap scripts for provisioned hosts
```

## Stack Deployment Order
1. [`stacks/vpc`](./stacks/vpc)
2. [`stacks/iam`](./stacks/iam)
3. [`stacks/security`](./stacks/security)
4. [`stacks/compute`](./stacks/compute)
5. [`stacks/bootstrap`](./stacks/bootstrap)
6. [`stacks/database`](./stacks/database)
7. [`stacks/storage`](./stacks/storage)

## Quick Start
```bash
git clone https://github.com/temitayocharles/terraform-module.git
cd terraform-module
cp resource/environment.yaml.template resource/environment.yaml
```

Validate all entrypoints:
```bash
terraform -chdir=resource init -backend=false
terraform -chdir=resource validate

for d in stacks/*; do
  terraform -chdir="$d" init -backend=false
  terraform -chdir="$d" validate
done
```

## Versions
- Terraform: `>= 1.6.0, < 2.0.0`
- AWS provider: `~> 5.0`

## CI
GitHub Actions workflow is at [`/.github/workflows/terraform-ci.yml`](./.github/workflows/terraform-ci.yml).

## Security
- `resource/environment.yaml` is gitignored.
- Keep secrets out of git; use AWS Secrets Manager / Vault.

## Module References
Each module has its own README under [`module/`](./module).



## Architecture Maps
- [DEPENDENCY_LADDER.md](./DEPENDENCY_LADDER.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)


## Argo CD Bootstrap
- `module/argocd-bootstrap` installs Argo CD and creates the root GitOps handoff.
- The caller chooses cluster access mode (`eks` or `kubeconfig`) so the same bootstrap design works for cloud and local clusters.
- The module is intentionally limited to bootstrap primitives only.
- Runtime platform tools such as Vault, Traefik, External Secrets, MinIO, and observability stay under GitOps ownership after bootstrap.
