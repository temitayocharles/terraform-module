
locals { enabled = var.s3_config.enabled }

resource "aws_s3_bucket" "this" {
  count  = var.s3_config.enabled ? 1 : 0
  bucket = var.s3_config.bucket_name
  tags   = { Name = var.s3_config.bucket_name }
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.s3_config.enabled ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = var.s3_config.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.s3_config.enabled ? 1 : 0
  bucket = aws_s3_bucket.this[0].bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
