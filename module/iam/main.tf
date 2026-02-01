resource "aws_iam_role" "jenkins_k8s_master" {
  count = var.iam_config.enable_instance_profiles ? 1 : 0

  name = lookup(var.iam_config.names, "jenkins_role_name", "${var.iam_config.project_config.name}-jenkins-k8s-master-role")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.iam_config.project_config.name}-jenkins-k8s-master-role"
    Project     = var.iam_config.project_config.name
    Environment = var.iam_config.project_config.environment
  }
}

resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  count = var.iam_config.enable_instance_profiles ? 1 : 0

  role       = aws_iam_role.jenkins_k8s_master[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "jenkins_ecr" {
  count = var.iam_config.enable_instance_profiles ? 1 : 0

    name = lookup(var.iam_config.names, "jenkins_ecr_policy_name", "${var.iam_config.project_config.name}-jenkins-ecr")
  role = aws_iam_role.jenkins_k8s_master[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins_k8s_master" {
  count = var.iam_config.enable_instance_profiles ? 1 : 0

  name = lookup(var.iam_config.names, "jenkins_profile_name", "${var.iam_config.project_config.name}-jenkins-k8s-master-profile")
  role = aws_iam_role.jenkins_k8s_master[0].name

  tags = {
    Name        = "${var.iam_config.project_config.name}-jenkins-k8s-master-profile"
    Project     = var.iam_config.project_config.name
    Environment = var.iam_config.project_config.environment
  }
}

# Worker role and profile
resource "aws_iam_role" "k8s_worker" {
  count = var.iam_config.enable_instance_profiles ? 1 : 0

  name = lookup(var.iam_config.names, "worker_role_name", "${var.iam_config.project_config.name}-k8s-worker-role")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.iam_config.project_config.name}-k8s-worker-role"
    Project     = var.iam_config.project_config.name
    Environment = var.iam_config.project_config.environment
  }
}

resource "aws_iam_role_policy_attachment" "k8s_worker_ssm" {
  count = var.iam_config.enable_instance_profiles ? 1 : 0

  role       = aws_iam_role.k8s_worker[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "k8s_worker_ecr" {
  count = var.iam_config.enable_instance_profiles ? 1 : 0

  name = lookup(var.iam_config.names, "worker_ecr_policy_name", "${var.iam_config.project_config.name}-k8s-worker-ecr")
  role = aws_iam_role.k8s_worker[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "k8s_worker" {
  count = var.iam_config.enable_instance_profiles ? 1 : 0

  name = lookup(var.iam_config.names, "worker_profile_name", "${var.iam_config.project_config.name}-k8s-worker-profile")
  role = aws_iam_role.k8s_worker[0].name

  tags = {
    Name        = "${var.iam_config.project_config.name}-k8s-worker-profile"
    Project     = var.iam_config.project_config.name
    Environment = var.iam_config.project_config.environment
  }
}
