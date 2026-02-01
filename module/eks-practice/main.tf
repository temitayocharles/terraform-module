resource "aws_iam_role" "eks_cluster_role" {
  count = var.eks_practice_config.enabled ? 1 : 0
  name  = "${var.eks_practice_config.name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_attach" {
  count      = var.eks_practice_config.enabled ? 1 : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_attach" {
  count      = var.eks_practice_config.enabled ? 1 : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_eks_cluster" "this" {
  count    = var.eks_practice_config.enabled ? 1 : 0
  name     = var.eks_practice_config.name
  role_arn = aws_iam_role.eks_cluster_role[0].arn
  version  = var.eks_practice_config.cluster_version

  vpc_config {
    subnet_ids              = var.eks_practice_config.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }
}
