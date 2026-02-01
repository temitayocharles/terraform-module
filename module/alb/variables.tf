variable "alb_config" {
  description = <<DESC
Application Load Balancer configuration object.

enabled: Set to true to enable creation of the Application Load Balancer (ALB). If false, no ALB resources will be created.
name: Name for the ALB. Used for resource naming and tagging.
subnet_ids: List of subnet IDs for ALB placement. Should be public subnets.
security_group_ids: List of security group IDs to associate with the ALB.
DESC
  type = object({
    enabled             = bool
    name                = string
    subnet_ids          = list(string)
    security_group_ids  = list(string)
    health_check_path   = string
    port                = number
    target_instance_ids = list(string)
  })
}
