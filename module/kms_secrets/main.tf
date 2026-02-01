locals { enabled = var.kms_secrets_config.enabled }
resource "aws_kms_key" "this" {
  count                   = var.kms_secrets_config.enabled ? 1 : 0
  description             = var.kms_secrets_config.name != "" ? "Key for ${var.kms_secrets_config.name}" : "Key"
  deletion_window_in_days = 30
  tags                    = { Name = var.kms_secrets_config.name }
}

resource "aws_kms_alias" "this" {
  count         = var.kms_secrets_config.enabled ? 1 : 0
  name          = "alias/${var.kms_secrets_config.name}"
  target_key_id = aws_kms_key.this[0].key_id
}

resource "aws_secretsmanager_secret" "this" {
  count      = var.kms_secrets_config.enabled ? 1 : 0
  name       = var.kms_secrets_config.name
  kms_key_id = aws_kms_key.this[0].arn
}
