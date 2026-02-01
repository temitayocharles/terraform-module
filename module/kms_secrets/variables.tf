variable "kms_secrets_config" {
  description = <<DESC
KMS & secrets configuration object.

enabled: Set to true to enable creation of KMS key and/or secrets resources. If false, no KMS or secrets resources will be created.
name: Name for the KMS key or secret. Used for resource naming and tagging.
DESC
  type = object({
    enabled = bool
    name    = string
  })
}
