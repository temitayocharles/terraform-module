variable "argocd_bootstrap_config" {
  description = <<DESC
Argo CD bootstrap configuration.

enabled: Set true to install and bootstrap Argo CD.
namespace: Namespace where Argo CD will be installed.
helm_repo: Helm repository for the Argo CD chart.
chart_version: Argo CD Helm chart version.
release_name: Helm release name.
helm_values: Optional Helm values map applied during install.
project_name: Name of the bootstrap AppProject used by the root application.
project_description: Description of the bootstrap AppProject.
project_source_repos: Source repos permitted in the bootstrap AppProject.
project_destinations: Destination namespaces/servers permitted in the bootstrap AppProject.
root_application_name: Name of the root Argo CD Application.
root_repo_url: Git repository URL for the root GitOps repo.
root_target_revision: Git revision for the root GitOps repo.
root_path: Path inside the root GitOps repo.
root_destination_server: Kubernetes API server URL.
root_destination_namespace: Namespace for the root Application destination.
repositories: Repository credentials Argo CD should know about.
DESC

  type = object({
    enabled              = bool
    namespace            = string
    helm_repo            = string
    chart_version        = string
    release_name         = string
    helm_values          = optional(map(any), {})
    project_name         = string
    project_description  = string
    project_source_repos = list(string)
    project_destinations = list(object({
      namespace = string
      server    = string
    }))
    root_application_name      = string
    root_repo_url              = string
    root_target_revision       = string
    root_path                  = string
    root_destination_server    = string
    root_destination_namespace = string
    repositories = list(object({
      name     = string
      url      = string
      username = string
      type     = optional(string, "git")
    }))
  })
}

variable "repo_passwords" {
  description = "Sensitive map of repository password/token values keyed by repository name."
  type        = map(string)
  default     = {}
  sensitive   = true
}


variable "kubectl_config" {
  description = <<DESC
Configuration for applying Argo CRD resources after the Helm release installs the CRDs.

For kubeconfig mode, supply kubeconfig_path and optionally kubeconfig_context.
For direct mode (for example EKS-derived auth), supply host, cluster_ca_certificate, and token.
DESC

  type = object({
    auth_mode              = string
    kubeconfig_path        = optional(string)
    kubeconfig_context     = optional(string)
    host                   = optional(string)
    cluster_ca_certificate = optional(string)
    token                  = optional(string)
  })
}
