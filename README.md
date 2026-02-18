# Terraform Module Repository

Modular AWS infrastructure with stack-by-stack deployment support.

## Start Here
- [`START_HERE.md`](./START_HERE.md)
- [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md)
- [`resource/environment.yaml.template`](./resource/environment.yaml.template)

## Repository Layout
```text
module/      Reusable Terraform modules
stacks/      Stack entrypoints (vpc, iam, security, compute, database, storage)
resource/    Combined/legacy root deployment
scripts/     Bootstrap scripts for provisioned hosts
```

## Stack Deployment Order
1. [`stacks/vpc`](./stacks/vpc)
2. [`stacks/iam`](./stacks/iam)
3. [`stacks/security`](./stacks/security)
4. [`stacks/compute`](./stacks/compute)
5. [`stacks/database`](./stacks/database)
6. [`stacks/storage`](./stacks/storage)

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

