
output "bucket_name" {
  value       = var.s3_config.enabled ? aws_s3_bucket.this[0].bucket : ""
  description = "S3 bucket name"
}

