# Terraform Module Repository - Infrastructure as Code

A comprehensive, enterprise-grade Terraform module collection for AWS infrastructure deployment. Designed for security, flexibility, and ease of use across multiple platforms and environments.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Deployment Models](#deployment-models)
- [Module Reference](#module-reference)
- [Configuration](#configuration)
- [Best Practices](#best-practices)
- [Support](#support)

## 🎯 Overview

This repository provides a modular, YAML-driven Terraform infrastructure management system with the following principles:

- **Zero Hardcoded Defaults**: All values must be explicitly configured
- **No Sensitive Credentials in Code**: All credentials managed through Vault/Secrets Manager
- **Stack-Based Deployment**: Deploy infrastructure components independently
- **Configuration-Driven**: Single YAML configuration file controls all deployments
- **Production-Ready**: Enterprise security, state management, and validation

### Key Features

✅ **Security-First**
- No hardcoded credentials or defaults
- AWS Secrets Manager integration ready
- S3 backend with encryption and locking
- IAM-based access control

✅ **Flexibility**
- Deploy individual infrastructure stacks
- Enable/disable modules without code changes
- Support for multiple environments
- Cross-platform compatibility

✅ **Maintainability**
- Clean, comment-free code
- Clear module organization
- Comprehensive documentation
- Validated configurations

## 🏗️ Architecture

### Stack Organization

The repository is organized into 6 independent deployment stacks:

```
stacks/
├── 1-vpc/              VPC and networking
├── 2-iam/              Identity and access management
├── 3-security/         Security groups and firewall rules
├── 4-compute/          EC2, ECS, EKS, ALB, Auto Scaling
├── 5-database/         RDS, Lambda, database-related services
└── 6-storage/          S3, KMS, EFS, ECR, Observability
```

Numbers indicate recommended deployment order.

### Deployment Models

#### Model A: Independent Stack Deployment (Recommended)
Deploy infrastructure components as needed:
```
Deploy VPC → Deploy IAM → Deploy Security → Deploy Compute → Deploy Database → Deploy Storage
```
Each stack has its own state file and can be deployed/destroyed independently.

#### Model B: Combined Deployment
Deploy all components together with unified state:
```
Deploy All (resource directory)
```
Uses single state file for all infrastructure.

#### Model C: Selective Deployment
Enable only needed modules:
```
modules_enabled:
  vpc: true
  ec2_cluster: true
  rds: false  # Skip this
  ecs_fargate: false  # Skip this
```

## 🚀 Quick Start

### Prerequisites

1. AWS account with appropriate permissions
2. Terraform >= 1.0
3. AWS CLI configured
4. S3 bucket for state management (create manually or use existing)
5. DynamoDB table for state locking (optional but recommended)

### Initial Setup

```bash
# 1. Clone repository
git clone <repo-url>
cd terraform-module

# 2. Create configuration
cp resource/environment.yaml.template resource/environment.yaml

# 3. Edit with your values (REQUIRED - no defaults)
nano resource/environment.yaml

# 4. Verify configuration
terraform validate  # from resource/ directory
```

### Deploy VPC Stack (Example)

```bash
cd stacks/1-vpc

# Initialize with S3 backend
terraform init \
  -backend-config="bucket=my-state-bucket" \
  -backend-config="key=vpc/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true"

# Review changes
terraform plan

# Deploy
terraform apply
```

## 📚 Deployment Models

### Model A: Stack-by-Stack (Recommended)

**When to use:** Development, testing, multi-team environments

**Advantages:**
- Independent lifecycle management
- Smaller state files
- Parallel deployment capability
- Team isolation

**Process:**
```bash
# Step 1: VPC
cd stacks/1-vpc && terraform apply

# Step 2: IAM
cd ../2-iam && terraform apply

# Step 3: Security
cd ../3-security && terraform apply

# Step 4: Compute
cd ../4-compute && terraform apply

# Step 5: Database
cd ../5-database && terraform apply

# Step 6: Storage
cd ../6-storage && terraform apply
```

### Model B: Combined Deployment

**When to use:** Proof of concept, single team, lab environments

**Advantages:**
- Single state file
- Simpler change tracking
- Atomic deployments

**Process:**
```bash
cd resource
terraform init -backend-config="..."
terraform apply
```

### Model C: Selective Components

**When to use:** Existing infrastructure, incremental updates

**Configuration:**
```yaml
modules_enabled:
  vpc: true           # Deploy VPC
  iam: true          # Deploy IAM
  jenkins_sg: true   # Enable this security group
  rds: false         # Skip RDS
  ecs_fargate: false # Skip ECS
```

**Deployment:**
```bash
cd resource
terraform apply  # Only selected modules deploy
```

## 📦 Module Reference

### Compute Modules

#### ec2-cluster
Master/worker EC2 cluster for Kubernetes or Jenkins.
```yaml
ec2_cluster_config:
  enabled: true
  master_count: 1
  worker_count: 2
  instance_type: "t3.medium"
  key_name: "your-key-pair"
```

#### ec2-instance
Standalone EC2 instances for tools, monitoring, etc.
```yaml
nexus_sonarqube_config:
  instance_count: 1
  instance_type: "t3.large"
  root_block_device:
    volume_size: 30
    volume_type: "gp3"
```

#### ecs-fargate
Containerized workloads on AWS ECS Fargate.
```yaml
ecs_fargate_config:
  enabled: true
  container_image: "nginx:latest"
  cpu: 256
  memory: 512
  desired_count: 1
```

#### eks-practice
Amazon EKS Kubernetes cluster with managed node groups.
```yaml
eks_config:
  enabled: true
  cluster_version: "1.27"
  desired_size: 2
  instance_types: ["t3.medium"]
```

#### alb
Application Load Balancer with target groups.
```yaml
alb_config:
  enabled: true
  port: 80
  health_check_path: "/health"
  target_instance_ids: []  # Auto-populated
```

#### autoscaling
Auto Scaling Group for dynamic capacity.
```yaml
autoscaling_config:
  enabled: true
  min_size: 1
  max_size: 3
  desired_capacity: 2
```

### Database Modules

#### rds
Managed relational database (PostgreSQL, MySQL, etc.).
```yaml
rds_config:
  enabled: true
  engine: "postgres"
  engine_version: "13"
  instance_class: "db.t3.micro"
  allocated_storage: 20
```

#### rotation_lambda
Lambda function for RDS credential rotation.
```yaml
rotation_lambda_config:
  enabled: true
  runtime: "python3.9"
  memory_size: 128
```

### Storage Modules

#### s3
Simple Storage Service buckets with versioning.
```yaml
s3_config:
  enabled: true
  bucket_name: "my-app-bucket"
  versioning: true
```

#### kms
Key Management Service for encryption.
```yaml
kms_config:
  enabled: true
  name: "my-kms-key"
```

#### efs
Elastic File System for shared storage.
```yaml
efs_config:
  enabled: true
  subnet_ids: []  # Auto-populated
```

#### ecr
Elastic Container Registry for Docker images.
```yaml
ecr_config:
  enabled: true
  name: "my-app-registry"
```

### Networking Modules

#### vpc
Virtual Private Cloud with subnets and routing.
```yaml
vpc_config:
  cidr: "10.0.0.0/16"
  availability_zones: ["us-east-1a", "us-east-1b"]
```

#### sg-dynamic
Flexible security group creation with rule templates.
```yaml
jenkins_sg_config:
  vpc_id: "vpc-xxxx"
  config:
    security_group_name: "jenkins-sg"
    allow_all: false
    inbound_rules: [...]
```

### Security Modules

#### iam
Identity and Access Management roles and policies.
```yaml
iam_config:
  enable_instance_profiles: true
  project_config:
    name: "my-project"
    environment: "prod"
```

#### oidc
OpenID Connect provider for GitHub Actions.
```yaml
oidc_config:
  enable_github_oidc: true
  providers_config:
    - github_org: "myorg"
      github_repo: "myrepo"
```

## ⚙️ Configuration

### environment.yaml Structure

All infrastructure is configured through a single YAML file:

```yaml
# Backend configuration
terraform_backend:
  bucket: "terraform-state-prod"
  key: "prod/terraform.tfstate"
  region: "us-east-1"
  encrypt: true
  dynamodb_table: "terraform-lock"

# AWS configuration
aws_config:
  region: "us-east-1"

# Module enable/disable flags
modules_enabled:
  vpc: true
  ec2_cluster: true
  rds: true
  # ... all other modules

# Module configurations (NO DEFAULTS)
vpc_config:
  cidr: "10.0.0.0/16"
  availability_zones: ["us-east-1a"]

ec2_cluster_config:
  enabled: true
  master_count: 1
  worker_count: 2
  instance_type: "t3.medium"

rds_config:
  enabled: true
  engine: "postgres"
  instance_class: "db.t3.micro"

# ... additional configurations
```

### Configuration Validation

All values must be explicitly set. No defaults exist in code:

```bash
# Terraform will fail with clear error if required values missing
terraform plan
# Error: Required configuration missing: rds_config.allocated_storage
```

### Remote State References

Link state from other Terraform deployments:

```yaml
remote_state:
  vpc:
    bucket: "existing-vpc-state"
    key: "vpc/terraform.tfstate"
    region: "us-east-1"
  iam:
    bucket: "existing-iam-state"
    key: "iam/terraform.tfstate"
    region: "us-east-1"
```

## 🏆 Best Practices

### Security

1. **Never commit sensitive values**
   ```bash
   # .gitignore
   resource/environment.yaml  # Contains credentials
   terraform.tfvars
   *.auto.tfvars
   ```

2. **Use AWS Secrets Manager for passwords**
   ```yaml
   rds_config:
     password: ""  # Leave empty
     create_secret: true  # Let Terraform manage
   ```

3. **Enable S3 encryption**
   ```yaml
   terraform_backend:
     encrypt: true  # Server-side encryption
   ```

4. **Use state locking**
   ```yaml
   terraform_backend:
     dynamodb_table: "terraform-lock"  # Prevents concurrent modifications
   ```

### Operational Excellence

1. **Always run terraform plan first**
   ```bash
   terraform plan -out=tfplan
   # Review carefully before applying
   terraform apply tfplan
   ```

2. **Tag all resources**
   ```yaml
   # In configurations
   tags:
     Environment: "prod"
     Team: "platform"
     Cost-Center: "engineering"
   ```

3. **Use workspaces for environments**
   ```bash
   terraform workspace new prod
   terraform workspace new staging
   ```

4. **Backup state files**
   ```bash
   # S3 versioning handles this automatically
   # But also backup locally
   aws s3 cp s3://my-state-bucket/prod/terraform.tfstate backup_$(date +%s).tfstate
   ```

### Maintenance

1. **Review and update versions regularly**
   - Terraform version
   - AWS provider version
   - Module versions

2. **Clean up unused resources**
   ```bash
   # Identify unused resources
   terraform state list | grep unused
   terraform state rm resource.name
   ```

3. **Document custom configurations**
   - Add comments in environment.yaml
   - Create decision records for infrastructure choices

## 🔧 Troubleshooting

### State Lock Issues
```bash
# If stuck in lock due to crashed process
terraform force-unlock <LOCK_ID>
```

### Module Source Errors
```bash
# Ensure module paths are correct relative to tfstate location
terraform init -upgrade
```

### Backend Configuration
```bash
# If backend changes, reinitialize
terraform init -reconfigure -backend-config="..."
```

### Missing Required Values
```bash
# Check environment.yaml for empty required fields
grep ": \"\"" resource/environment.yaml | head -20
```

## 📖 Additional Documentation

- **DEPLOYMENT_GUIDE.md** - Detailed stack deployment instructions
- **FIXES_APPLIED.md** - Previous fixes and known issues
- **TERRAFORM_REFACTORING_SUMMARY.md** - Refactoring documentation
- **module/*/README.md** - Individual module documentation

## 🤝 Contributing

1. Update `environment.yaml.template` for new configurations
2. Follow HCL formatting standards
3. Add module validation
4. Test with different deployment models
5. Document changes in commit messages

## 📄 License

[Your License Here]

## 🆘 Support

For issues or questions:
1. Check module-specific README files
2. Review troubleshooting section
3. Check git history for similar issues
4. Create detailed issue report

---

**Last Updated:** 2026-02-01  
**Terraform Version:** >= 1.0  
**AWS Provider Version:** ~> 5.0
