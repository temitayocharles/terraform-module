locals { enabled = var.ecr_config.enabled }
resource "aws_ecr_repository" "this" {
  count                = var.ecr_config.enabled ? 1 : 0
  name                 = var.ecr_config.name
  image_tag_mutability = "MUTABLE"
  tags                 = { Name = var.ecr_config.name }
}

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.ecr_config.enabled ? 1 : 0
  repository = aws_ecr_repository.this[0].name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire untagged images"
      selection    = { tagStatus = "untagged", countType = "imageCountMoreThan", countNumber = 10 }
      action       = { type = "expire" }
    }]
  })
}
