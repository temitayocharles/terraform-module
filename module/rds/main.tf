locals { enabled = var.rds_config.enabled }
resource "aws_db_subnet_group" "this" {
  count      = var.rds_config.enabled && length(var.rds_config.subnet_ids) > 0 ? 1 : 0
  name       = "rds-subnet-${substr(md5(join("-", var.rds_config.subnet_ids)), 0, 8)}"
  subnet_ids = var.rds_config.subnet_ids
}

resource "random_password" "this" {
  count   = var.rds_config.enabled && var.rds_config.create_secret ? 1 : 0
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "aws_secretsmanager_secret" "this" {
  count = var.rds_config.enabled && var.rds_config.create_secret ? 1 : 0
  name  = var.rds_config.secret_name != "" ? var.rds_config.secret_name : "${var.rds_config.db_name}-credentials"
}

resource "aws_secretsmanager_secret_version" "this" {
  count         = var.rds_config.enabled && var.rds_config.create_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.this[0].id
  secret_string = jsonencode({ username = var.rds_config.username, password = random_password.this[0].result })
}

# Create a security group for RDS when none provided
resource "aws_security_group" "this" {
  count       = var.rds_config.enabled && length(var.rds_config.security_group_ids) == 0 ? 1 : 0
  name        = "${var.rds_config.db_name}-rds-sg"
  description = "RDS security group for ${var.rds_config.db_name}"
  vpc_id      = var.rds_config.vpc_id != "" ? var.rds_config.vpc_id : null
  # If vpc_id is not provided and no security_group_ids are supplied, this will create an SG without a VPC and will likely fail; set `vpc_id` when creating in a VPC.
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = length(var.rds_config.allowed_source_cidr) > 0 ? var.rds_config.allowed_source_cidr : []
    security_groups = length(var.rds_config.allowed_source_security_group_ids) > 0 ? var.rds_config.allowed_source_security_group_ids : []
    description     = "Postgres access"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  effective_sg_ids = length(var.rds_config.security_group_ids) > 0 ? var.rds_config.security_group_ids : (length(aws_security_group.this) > 0 ? [aws_security_group.this[0].id] : [])
}

resource "aws_db_instance" "this" {
  count                  = var.rds_config.enabled ? 1 : 0
  allocated_storage      = var.rds_config.allocated_storage
  engine                 = var.rds_config.engine
  engine_version         = var.rds_config.engine_version
  instance_class         = var.rds_config.instance_class
  username               = var.rds_config.username
  password               = var.rds_config.create_secret ? random_password.this[0].result : var.rds_config.password
  skip_final_snapshot    = var.rds_config.skip_final_snapshot
  publicly_accessible    = false
  vpc_security_group_ids = local.effective_sg_ids
  db_subnet_group_name   = length(aws_db_subnet_group.this) > 0 ? aws_db_subnet_group.this[0].id : null
  tags                   = { Name = "rds-${var.rds_config.engine}" }
}

# Optional rotation configuration (requires a rotation Lambda ARN)
resource "aws_secretsmanager_secret_rotation" "this" {
  count               = var.rds_config.enabled && var.rds_config.create_secret && var.rds_config.rotation_lambda_arn != "" ? 1 : 0
  secret_id           = aws_secretsmanager_secret.this[0].id
  rotation_lambda_arn = var.rds_config.rotation_lambda_arn
  rotation_rules {
    automatically_after_days = var.rds_config.rotation_days
  }
}
