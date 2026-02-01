locals { enabled = var.alb_config.enabled }
resource "aws_security_group" "alb" {
  count       = var.alb_config.enabled ? 1 : 0
  name        = "${var.alb_config.name}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.alb_config.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "this" {
  count              = var.alb_config.enabled ? 1 : 0
  name               = var.alb_config.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = length(var.alb_config.security_group_ids) > 0 ? var.alb_config.security_group_ids : (aws_security_group.alb[0].id != null ? [aws_security_group.alb[0].id] : [])
  subnets            = var.alb_config.subnet_ids
  tags               = { Name = var.alb_config.name }
}

resource "aws_lb_target_group" "this" {
  count    = var.alb_config.enabled ? 1 : 0
  name     = "${var.alb_config.name}-tg"
  port     = var.alb_config.port
  protocol = "HTTP"
  vpc_id   = var.alb_config.vpc_id
}

resource "aws_lb_listener" "http" {
  count             = var.alb_config.enabled ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = var.alb_config.port
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}

resource "aws_lb_target_group_attachment" "instances" {
  count            = var.alb_config.enabled && length(var.alb_config.target_instance_ids) > 0 ? length(var.alb_config.target_instance_ids) : 0
  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = var.alb_config.target_instance_ids[count.index]
  port             = var.alb_config.port
}
