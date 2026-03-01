output "namespace" {
  value = var.argocd_bootstrap_config.enabled ? var.argocd_bootstrap_config.namespace : ""
}

output "release_name" {
  value = var.argocd_bootstrap_config.enabled ? var.argocd_bootstrap_config.release_name : ""
}

output "root_application_name" {
  value = var.argocd_bootstrap_config.enabled ? var.argocd_bootstrap_config.root_application_name : ""
}

output "repository_secret_names" {
  value = [for repo in var.argocd_bootstrap_config.repositories : "argocd-repo-${repo.name}"]
}
