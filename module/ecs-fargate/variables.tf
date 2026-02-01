variable "ecs_fargate_config" {
  description = <<DESC
ECS Fargate configuration object.

enabled: Set to true to enable creation of ECS Fargate resources. If false, no ECS resources will be created.
name: Name for the ECS service and related resources.
subnet_ids: List of subnet IDs for ECS tasks. Should be private subnets.
security_group_ids: List of security group IDs for ECS tasks.
container_image: Docker image to deploy (e.g., 'nginx:stable-alpine').
cpu: CPU units to allocate per task (e.g., 256, 512).
memory: Memory (in MB) to allocate per task (e.g., 512, 1024).
desired_count: Number of ECS tasks to run.
DESC
  type = object({
    enabled            = bool
    name               = string
    subnet_ids         = list(string)
    security_group_ids = list(string)
    container_image    = string
    cpu                = number
    memory             = number
    desired_count      = number
  })
}
