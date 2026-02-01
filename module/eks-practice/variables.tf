variable "eks_practice_config" {
  description = <<DESC
EKS practice cluster configuration object.

enabled: Set to true to enable creation of the EKS cluster. If false, no EKS resources will be created.
name: Name for the EKS cluster. Used for resource naming and tagging.
subnet_ids: List of subnet IDs for EKS worker nodes and control plane. Should be private subnets.
cluster_version: Kubernetes version for the EKS cluster (e.g., '1.27').
DESC
  type = object({
    enabled         = bool
    name            = string
    subnet_ids      = list(string)
    cluster_version = string
  })
}
