locals { enabled = var.autoscaling_config.enabled }
resource "aws_launch_template" "this" {
  count                  = var.autoscaling_config.enabled ? 1 : 0
  name_prefix            = "${var.autoscaling_config.name}-lt-"
  image_id               = var.autoscaling_config.ami
  instance_type          = var.autoscaling_config.instance_type
  key_name               = var.autoscaling_config.key_name != "" ? var.autoscaling_config.key_name : null
  vpc_security_group_ids = length(var.autoscaling_config.security_group_ids) > 0 ? var.autoscaling_config.security_group_ids : null
  user_data              = var.autoscaling_config.user_data != "" ? base64encode(var.autoscaling_config.user_data) : null
  iam_instance_profile {
    name = var.autoscaling_config.iam_instance_profile != "" ? var.autoscaling_config.iam_instance_profile : (var.autoscaling_config.create_iam_profile && var.autoscaling_config.enabled ? aws_iam_instance_profile.this[0].name : null)
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  count            = var.autoscaling_config.enabled ? 1 : 0
  name             = var.autoscaling_config.name
  max_size         = var.autoscaling_config.max_size
  min_size         = var.autoscaling_config.min_size
  desired_capacity = var.autoscaling_config.desired_capacity
  launch_template {
    id      = aws_launch_template.this[0].id
    version = "$LATEST"
  }
  target_group_arns   = length(var.autoscaling_config.target_group_arns) > 0 ? var.autoscaling_config.target_group_arns : null
  vpc_zone_identifier = var.autoscaling_config.subnet_ids
  tag {
    key                 = "Name"
    value               = var.autoscaling_config.name
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "this" {
  count = var.autoscaling_config.enabled && var.autoscaling_config.create_iam_profile ? 1 : 0
  name  = "${var.autoscaling_config.name}-instance-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" }, Effect = "Allow" }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr" {
  count      = var.autoscaling_config.enabled && var.autoscaling_config.create_iam_profile ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.autoscaling_config.enabled && var.autoscaling_config.create_iam_profile ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw" {
  count      = var.autoscaling_config.enabled && var.autoscaling_config.create_iam_profile ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "this" {
  count = var.autoscaling_config.enabled && var.autoscaling_config.create_iam_profile ? 1 : 0
  name  = "${var.autoscaling_config.name}-instance-profile"
  role  = aws_iam_role.this[0].name
}
