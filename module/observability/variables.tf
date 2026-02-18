variable "observability_config" {
  description = <<DESC
Observability configuration object.

enabled: Set to true to enable creation of observability resources (e.g., CloudWatch log groups). If false, no observability resources will be created.
log_group_prefix: Prefix for CloudWatch log group names. Used for resource naming and tagging.
DESC
  type = object({
    enabled          = bool
    log_group_prefix = string
  })
}
