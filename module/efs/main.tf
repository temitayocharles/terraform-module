
resource "aws_efs_file_system" "this" {
  count     = var.efs_config.enabled ? 1 : 0
  encrypted = true
  tags      = { Name = "efs-${substr(md5(join("-", var.efs_config.subnet_ids)), 0, 8)}" }
}

resource "aws_efs_mount_target" "this" {
  count          = var.efs_config.enabled ? length(var.efs_config.subnet_ids) : 0
  file_system_id = aws_efs_file_system.this[0].id
  subnet_id      = var.efs_config.subnet_ids[count.index]
}
