# Terraform Module Deployment Guide

## Architecture

This Terraform module uses a **stack-based deployment system** allowing independent deployment of infrastructure components without requiring all modules to be enabled simultaneously.

### Stack Organization

```
stacks/
├── vpc/              VPC and networking
├── iam/              Identity and access management
├── security/         Security groups
├── compute/          EC2, ECS, EKS, ALB, ASG
├── database/         RDS, Lambda functions
└── storage/          S3, KMS, EFS, ECR, Observability
```

### Legacy Structure

```
resource/
└── main.tf           Combined deployment (all modules together)
```

## Prerequisites

### AWS Setup

1. Create S3 bucket for Terraform state
2. Create DynamoDB table for state locking
3. Configure AWS credentials
4. Create required resources (VPC, subnets, key pairs, etc.)

### Local Setup

```bash
aws configure
export AWS_PROFILE=your-profile
```

## Configuration

### 1. Environment File

Copy and configure the environment file:

```bash
cp resource/environment.yaml.template resource/environment.yaml
```

### 2. Set Required Values

All values in `environment.yaml` MUST be explicitly set. No defaults.

**Required for all deployments:**
```yaml
terraform_backend:
  bucket: "your-state-bucket"
  key: "terraform/state.tfstate"
  region: "us-east-1"
  encrypt: true
  dynamodb_table: "terraform-lock"

aws_config:
  region: "us-east-1"
```

**Required for remote state imports:**
```yaml
remote_state:
  vpc:
    bucket: "your-vpc-state-bucket"
    key: "vpc/state.tfstate"
    region: "us-east-1"
  iam:
    bucket: "your-iam-state-bucket"
    key: "iam/state.tfstate"
    region: "us-east-1"
```

## Individual Stack Deployment

### VPC Stack

**Enable in environment.yaml:**
```yaml
modules_enabled:
  vpc: true
```

**Deploy:**
```bash
cd stacks/vpc
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=vpc/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true"

terraform plan
terraform apply
```

**Save outputs for other stacks:**
```bash
terraform output -json > vpc_outputs.json
```

### IAM Stack

**Enable in environment.yaml:**
```yaml
modules_enabled:
  iam: true
  oidc: false
```

**Deploy:**
```bash
cd stacks/iam
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=iam/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan
terraform apply
```

### Security Stack (Security Groups)

**Enable in environment.yaml:**
```yaml
modules_enabled:
  jenkins_sg: true
  k8s_master_sg: true
  k8s_worker_sg: true
  tools_sg: true
  monitoring_sg: true
```

**Prerequisites:**
- VPC ID available (from VPC stack output)

**Deploy:**
```bash
cd stacks/security
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=security/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan
terraform apply
```

### Compute Stack

**Enable in environment.yaml:**
```yaml
modules_enabled:
  ec2_cluster: true
  nexus_sonarqube: false
  monitoring: false
  ecs_fargate: false
  eks: false
  alb: true
  autoscaling: false
```

**Prerequisites:**
- VPC deployed
- Security groups created
- SSH key pair exists in AWS
- IAM instance profiles created

**Deploy:**
```bash
cd stacks/compute
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=compute/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan
terraform apply
```

### Database Stack

**Enable in environment.yaml:**
```yaml
modules_enabled:
  rotation_lambda: false
  rds: true
```

**Prerequisites:**
- VPC deployed
- Security groups created
- RDS password stored in Secrets Manager OR provided in environment.yaml

**Deploy:**
```bash
cd stacks/database
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=database/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan
terraform apply
```

### Storage Stack

**Enable in environment.yaml:**
```yaml
modules_enabled:
  s3: true
  kms: false
  efs: false
  ecr: false
  observability: false
  route53_acm: false
```

**Deploy:**
```bash
cd stacks/storage
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=storage/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan
terraform apply
```

## Combined Deployment (All Modules)

For deploying all modules together with unified state:

```bash
cd resource
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=all/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan
terraform apply
```

**Note:** Ensure ALL required configurations in `environment.yaml` are set before running combined deployment.

## Validation

All configurations are validated before deployment:

```bash
terraform validate
terraform plan -out=tfplan
```

Review the plan carefully. No defaults means every resource must be explicitly configured.

## Secrets Management

### Avoid Hardcoding Credentials

Use AWS Secrets Manager:

```yaml
rds_config:
  enabled: true
  create_secret: true
  secret_name: "my-rds-credentials"
```

### Reference External Secrets

```bash
aws secretsmanager get-secret-value \
  --secret-id my-rds-credentials \
  --query SecretString \
  --output text | jq -r '.password'
```

## Troubleshooting

### Missing Required Values

Error: `local.env.xxx.yyy: cannot access key on null value`

**Solution:** Ensure all required fields in `environment.yaml` are set. No values are optional.

### S3 Backend Not Found

Error: `error reading S3 Bucket...`

**Solution:** 
1. Verify bucket exists and is accessible
2. Check AWS credentials
3. Verify S3 bucket name and region

### Security Group Already Exists

**Solution:** Either use remote state reference or manage through existing infrastructure.

## Deployment Order (Recommended)

1. **VPC** (if creating new)
2. **IAM** (if creating new instance profiles)
3. **Security Groups** (depends on VPC)
4. **Compute** (depends on VPC, SG, IAM)
5. **Database** (depends on VPC, SG, Compute)
6. **Storage** (independent, but may reference Compute)

## State Management

Each stack maintains separate state. To migrate between stacks:

```bash
terraform state pull > state.json
terraform state push state.json
```

## Backing Up State

Always backup Terraform state:

```bash
aws s3 cp s3://your-bucket/terraform/state.tfstate backup_state_$(date +%s).tfstate
```

## Cleanup

Destroy resources in reverse deployment order:

```bash
cd stacks/storage && terraform destroy
cd ../database && terraform destroy
cd ../compute && terraform destroy
cd ../security && terraform destroy
cd ../iam && terraform destroy
cd ../vpc && terraform destroy
```

**Warning:** Destroying will remove all resources. Ensure data is backed up first.

## Security Best Practices

1. **Never commit `environment.yaml`** to Git if it contains sensitive values
2. **Store sensitive values in AWS Secrets Manager**
3. **Use IAM roles for Terraform execution, not access keys**
4. **Enable S3 encryption for state backend**
5. **Enable DynamoDB encryption for state locking**
6. **Restrict S3 bucket access to specific IAM principals**
7. **Enable versioning on S3 state bucket**
8. **Use terraform.tfvars for secrets, not environment.yaml**

## Support

For module-specific documentation, see:
- `module/*/README.md` - Module details
- `FIXES_APPLIED.md` - Previous fixes and known issues
- `README.md` - Project overview
