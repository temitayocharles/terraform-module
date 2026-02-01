variable "aws_config" {
  description = "AWS configuration settings.\nregion: The AWS region where all resources will be deployed (e.g., 'us-east-1'). User must set this."
  type = object({
    region = string
  })
}

variable "ami_config" {
  description = "AMI configuration.\nid: The AMI ID to use for EC2 instances (e.g., 'ami-xxxxxxxx'). User must set this, or it can be discovered via automation."
  type = object({
    id = string
  })
}

variable "ssh_config" {
  description = "SSH configuration.\nkey_name: Name of the AWS EC2 Key Pair for SSH access.\nallowed_cidr: List of CIDR blocks allowed to SSH (e.g., ['0.0.0.0/0'] for open access, but restrict in production)."
  type = object({
    key_name     = string
    allowed_cidr = list(string)
  })
}

variable "instance_types" {
  description = "EC2 instance type configuration.\nmaster: Instance type for master nodes (e.g., 't3.medium').\nworker: Instance type for worker nodes.\nmonitoring: Instance type for monitoring node. All values are user-defined."
  type = object({
    master     = string
    worker     = string
    monitoring = string
  })
}

variable "project_config" {
  description = "Project tagging and naming configuration.\nname: Project name for tagging and resource naming.\nenvironment: Environment name (e.g., 'dev', 'prod'). Both are user-defined."
  type = object({
    name        = string
    environment = string
  })
}

variable "feature_flags" {
  description = "Feature toggles for optional infrastructure components.\nenable_monitoring_instance: Enable/disable monitoring EC2 instance.\nenable_tools_instance: Enable/disable tools EC2 instance.\nenable_worker_2: Enable/disable a second worker node. All are user-defined booleans."
  type = object({
    enable_monitoring_instance = bool
    enable_tools_instance      = bool
    enable_worker_2            = bool
  })
}
variable "vpc_id" {
  description = "VPC id where security groups will be created.\nIf empty, the module will attempt to discover the VPC from remote state or data sources.\nUser can override for custom VPCs."
  type        = string
  default     = ""
}
