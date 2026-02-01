resource "aws_ecs_cluster" "this" {
  count = var.ecs_fargate_config.enabled ? 1 : 0
  name  = var.ecs_fargate_config.name
}

resource "aws_iam_role" "task_exec" {
  count = var.ecs_fargate_config.enabled ? 1 : 0
  name  = "${var.ecs_fargate_config.name}-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_exec_attach" {
  count      = var.ecs_fargate_config.enabled ? 1 : 0
  role       = aws_iam_role.task_exec[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "this" {
  count                    = var.ecs_fargate_config.enabled ? 1 : 0
  family                   = var.ecs_fargate_config.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.ecs_fargate_config.cpu)
  memory                   = tostring(var.ecs_fargate_config.memory)

  execution_role_arn = var.ecs_fargate_config.enabled ? aws_iam_role.task_exec[0].arn : null

  container_definitions = jsonencode([
    {
      name         = "practice"
      image        = var.ecs_fargate_config.container_image
      essential    = true
      portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
    }
  ])
}

resource "aws_ecs_service" "this" {
  count           = var.ecs_fargate_config.enabled ? 1 : 0
  name            = var.ecs_fargate_config.name
  cluster         = aws_ecs_cluster.this[0].id
  task_definition = aws_ecs_task_definition.this[0].arn
  desired_count   = var.ecs_fargate_config.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_fargate_config.subnet_ids
    security_groups  = var.ecs_fargate_config.security_group_ids
    assign_public_ip = true
  }
}
