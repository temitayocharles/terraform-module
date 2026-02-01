variable "eks_practice_config" {
  description = <<DESC
EKS practice cluster configuration object.

enabled: Set to true to enable creation of the EKS cluster. If false, no EKS resources will be created.
name: Name for the EKS cluster. Used for resource naming and tagging.
subnet_ids: List of subnet IDs for EKS worker nodes and control plane. Should be private subnets.
cluster_version: Kubernetes version for the EKS cluster (e.g., '1.27').
desired_size: Desired number of worker nodes (default: 2).
min_size: Minimum number of worker nodes (default: 1).
max_size: Maximum number of worker nodes (default: 4).
instance_types: List of instance types for worker nodes (default: ["t3.medium"]).
DESC
  type = object({
    enabled         = bool
    name            = string
    subnet_ids      = list(string)
    cluster_version = string
    desired_size    = optional(number, 2)
    min_size        = optional(number, 1)
    max_size        = optional(number, 4)
    instance_types  = optional(list(string), ["t3.medium"])
  })
}
