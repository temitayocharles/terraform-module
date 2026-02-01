
variable "s3_config" {
  description = <<DESC
S3 configuration object.

enabled: Set to true to enable creation of the S3 bucket. If false, no S3 resources will be created.
bucket_name: Name for the S3 bucket. Used for resource naming and tagging.
versioning: Set to true to enable versioning on the bucket.
acl: Access control list for the bucket (e.g., 'private', 'public-read').
force_destroy: If true, allows the bucket to be destroyed even if it contains objects (use with caution).
DESC
  type = object({
    enabled     = bool
    bucket_name = string
    versioning  = bool
    acl           = string
    force_destroy = bool
  })
}
