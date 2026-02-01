variable "vpc_config" {
  description = <<DESC
VPC configuration object.

enabled: Set to true to enable creation of a new VPC. If false, this module will not create any VPC resources.

project_config: Object containing project-level metadata for tagging and naming. Includes:
  - name: Project name (user-defined, used for resource names and tags)
  - environment: Environment name (e.g., 'dev', 'prod')

cidr: The CIDR block for the VPC (e.g., '10.0.0.0/16'). User must set this to match their network plan.
DESC
  type = object({
    enabled = bool
    project_config = object({
      name        = string
      environment = string
    })
    cidr = string
  })
}
