# ec2-cluster module

Reusable EC2 cluster module for master/worker patterns (Jenkins, Kubernetes, etc.), fully YAML/object-driven.

## Input Schema (`ec2_cluster_config`)

```
object({
  enabled                  = bool
  master_count             = number
  worker_count             = number
  ami                      = string
  master_instance_type     = string
  worker_instance_type     = string
  key_name                 = string
  subnet_id                = string
  vpc_security_group_ids   = list(string)
  iam_instance_profile     = string
  master_user_data         = string
  worker_user_data         = string
  tags                     = map(string)
})
```

## Example YAML (`environment.yaml`)

```yaml
ec2_cluster_config:
  enabled: true
  master_count: 1
  worker_count: 2
  ami: "ami-xxxxxxxx"
  master_instance_type: "t3.medium"
  worker_instance_type: "t3.medium"
  key_name: "my-key"
  subnet_id: "subnet-xxxx"
  vpc_security_group_ids:
    - "sg-xxxx"
  iam_instance_profile: "my-profile"
  master_user_data: "${file(../scripts/jenkins-k8s-master-setup.sh)}"
  worker_user_data: "${file(../scripts/k8s-worker-setup.sh)}"
  tags:
    Project: "my-project"
    Environment: "dev"
```

## Outputs
- `master_instance_ids`, `master_public_ips`
- `worker_instance_ids`, `worker_public_ips`

## Usage

```
module "ec2_cluster" {
  source              = "../module/ec2-cluster"
  ec2_cluster_config  = local.env.ec2_cluster_config
}
```

