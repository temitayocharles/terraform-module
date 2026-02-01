
variable "autoscaling_config" {
  description = <<DESC
AutoScaling configuration object.

enabled: Set to true to enable creation of the Auto Scaling Group (ASG). If false, no ASG resources will be created.
name: Name for the ASG. Used for resource naming and tagging.
instance_type: EC2 instance type for ASG members (e.g., 't3.medium').
ami: AMI ID to use for ASG instances.
subnet_ids: List of subnet IDs for ASG placement. Should be private subnets.
security_group_ids: List of security group IDs to associate with ASG instances.
key_name: Name of the EC2 Key Pair for SSH access.
user_data: User data script to run on instance launch (can be templated or file reference).
iam_instance_profile: Name of the IAM instance profile to attach to instances.
target_group_arns: List of target group ARNs for ALB/NLB integration.
create_iam_profile: If true, this module will create the IAM instance profile.
min_size: Minimum number of instances in the ASG.
max_size: Maximum number of instances in the ASG.
desired_capacity: Desired number of instances in the ASG at launch.
DESC
  type = object({
    enabled              = bool
    name                 = string
    instance_type        = string
    ami                  = string
    subnet_ids           = list(string)
    security_group_ids   = list(string)
    key_name             = string
    user_data            = string
    iam_instance_profile = string
    target_group_arns    = list(string)
    create_iam_profile   = bool
    min_size             = number
    max_size             = number
    desired_capacity     = number
  })
}
