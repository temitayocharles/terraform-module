variable "iam_config" {
  description = <<DESC
IAM configuration object.

project_config: Object containing project-level metadata for tagging and naming. Includes:
  - name: Project name (user-defined, used for resource names and tags)
  - environment: Environment name (e.g., 'dev', 'prod')

enable_instance_profiles: Set to true to create EC2 instance profiles for roles. If false, no instance profiles will be created.

names: Map containing names for IAM resources. Includes:
  - jenkins_role_name: Name for the Jenkins IAM role (user-defined or generated)
  - jenkins_profile_name: Name for the Jenkins instance profile (user-defined or generated)
DESC
  type = object({
    project_config = object({
      name        = string
      environment = string
    })
    enable_instance_profiles = bool
    names                    = map(string)
  })
}
