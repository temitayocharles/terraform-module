locals { enabled = var.observability_config.enabled }
resource "aws_cloudwatch_log_group" "this" {
  count             = var.observability_config.enabled ? 1 : 0
  name              = "${var.observability_config.log_group_prefix}-logs"
  retention_in_days = 14
}

resource "aws_cloudwatch_dashboard" "this" {
  count          = var.observability_config.enabled ? 1 : 0
  dashboard_name = "${var.observability_config.log_group_prefix}-dashboard"
  dashboard_body = jsonencode({
    widgets = []
  })
}
