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

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_attach,
    aws_iam_role_policy_attachment.eks_vpc_attach
  ]
}

# EKS Node Group (Worker nodes)
resource "aws_iam_role" "eks_node_role" {
  count = var.eks_practice_config.enabled ? 1 : 0
  name  = "${var.eks_practice_config.name}-node-role"

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
}

resource "aws_iam_role_policy_attachment" "eks_node_attach_worker" {
  count      = var.eks_practice_config.enabled ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_attach_cni" {
  count      = var.eks_practice_config.enabled ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_attach_registry" {
  count      = var.eks_practice_config.enabled ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "this" {
  count           = var.eks_practice_config.enabled ? 1 : 0
  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = "${var.eks_practice_config.name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role[0].arn
  subnet_ids      = var.eks_practice_config.subnet_ids
  instance_types  = var.eks_practice_config.instance_types

  scaling_config {
    desired_size = var.eks_practice_config.desired_size
    min_size     = var.eks_practice_config.min_size
    max_size     = var.eks_practice_config.max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_attach_worker,
    aws_iam_role_policy_attachment.eks_node_attach_cni,
    aws_iam_role_policy_attachment.eks_node_attach_registry
  ]
}
