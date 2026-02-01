output "cluster_name" {
  value = var.eks_practice_config.enabled && length(aws_eks_cluster.this) > 0 ? aws_eks_cluster.this[0].name : ""
}

output "cluster_endpoint" {
  value = var.eks_practice_config.enabled && length(aws_eks_cluster.this) > 0 ? aws_eks_cluster.this[0].endpoint : ""
}
