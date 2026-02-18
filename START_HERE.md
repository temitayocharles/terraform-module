# START HERE

This is the canonical playbook for using this repo.

## 1. Prerequisites
- Terraform `>= 1.6.0, < 2.0.0`
- AWS credentials configured (`aws sts get-caller-identity` should work)
- Existing S3 backend bucket (and optional DynamoDB lock table)

## 2. Configure Environment
```bash
cp resource/environment.yaml.template resource/environment.yaml
```
Set all required values in `resource/environment.yaml`.

## 3. Validate Before Deploy
```bash
terraform fmt -recursive
terraform -chdir=resource init -backend=false
terraform -chdir=resource validate

for d in stacks/*; do
  terraform -chdir="$d" init -backend=false
  terraform -chdir="$d" validate
done
```

## 4. Deploy by Stack (Recommended)
Deploy in this order:
1. `stacks/vpc`
2. `stacks/iam`
3. `stacks/security`
4. `stacks/compute`
5. `stacks/database`
6. `stacks/storage`

Example for one stack:
```bash
cd stacks/vpc
terraform init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="key=vpc/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="encrypt=true"

terraform plan
terraform apply
```

## 5. Combined Deployment (Legacy)
`resource/` is kept for backward compatibility only. Stack-based deployment is the supported path.

If you still need combined mode:
```bash
terraform -chdir=resource init -backend-config="..."
terraform -chdir=resource plan
terraform -chdir=resource apply
```

## 6. Destroy / Cleanup
Destroy in reverse order for stack-based deployments:
1. `stacks/storage`
2. `stacks/database`
3. `stacks/compute`
4. `stacks/security`
5. `stacks/iam`
6. `stacks/vpc`

## 7. References
- [`README.md`](./README.md)
- [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md)
- [`resource/environment.yaml.template`](./resource/environment.yaml.template)
