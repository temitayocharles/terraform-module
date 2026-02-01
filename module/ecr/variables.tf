variable "ecr_config" {
  description = <<DESC
ECR configuration object.

enabled: Set to true to enable creation of the ECR repository. If false, no ECR resources will be created.
name: Name for the ECR repository. Used for resource naming and tagging.
DESC
  type = object({
    enabled = bool
    name    = string
  })
}
