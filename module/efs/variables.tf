
variable "efs_config" {
  description = <<DESC
EFS configuration object.

enabled: Set to true to enable creation of the EFS file system for this environment. If false, no EFS resources will be created by this module.

subnet_ids: List of subnet IDs where the EFS mount targets will be created. These should be private subnets in your VPC. Can be auto-populated from remote state or set manually.
DESC
  type = object({
    enabled    = bool
    subnet_ids = list(string)
  })
}
