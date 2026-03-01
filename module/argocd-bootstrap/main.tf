terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

locals {
  enabled      = var.argocd_bootstrap_config.enabled
  namespace    = var.argocd_bootstrap_config.namespace
  release_name = var.argocd_bootstrap_config.release_name
  repo_credentials = {
    for repo in var.argocd_bootstrap_config.repositories : repo.name => repo
  }
  helm_values = length(keys(try(var.argocd_bootstrap_config.helm_values, {}))) > 0 ? [yamlencode(var.argocd_bootstrap_config.helm_values)] : []
}

resource "kubernetes_namespace_v1" "argocd" {
  count = local.enabled ? 1 : 0

  metadata {
    name = local.namespace
  }
}

resource "helm_release" "argocd" {
  count = local.enabled ? 1 : 0

  name             = local.release_name
  repository       = var.argocd_bootstrap_config.helm_repo
  chart            = "argo-cd"
  version          = var.argocd_bootstrap_config.chart_version
  namespace        = local.namespace
  create_namespace = false
  wait             = true
  atomic           = true
  timeout          = 600
  cleanup_on_fail  = true
  values           = local.helm_values

  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "kubernetes_manifest" "repository_secret" {
  for_each = local.enabled ? local.repo_credentials : {}

  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "argocd-repo-${each.key}"
      namespace = local.namespace
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }
    type = "Opaque"
    stringData = {
      name     = each.value.name
      type     = try(each.value.type, "git")
      url      = each.value.url
      username = each.value.username
      password = lookup(var.repo_passwords, each.key, "")
    }
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "project" {
  count = local.enabled ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = var.argocd_bootstrap_config.project_name
      namespace = local.namespace
    }
    spec = {
      description = var.argocd_bootstrap_config.project_description
      sourceRepos = var.argocd_bootstrap_config.project_source_repos
      destinations = [
        for destination in var.argocd_bootstrap_config.project_destinations : {
          namespace = destination.namespace
          server    = destination.server
        }
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      namespaceResourceBlacklist = [
        {
          group = ""
          kind  = "ResourceQuota"
        },
        {
          group = ""
          kind  = "LimitRange"
        }
      ]
      orphanedResources = {
        warn = true
      }
    }
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "root_application" {
  count = local.enabled ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.argocd_bootstrap_config.root_application_name
      namespace = local.namespace
      annotations = {
        "argocd.argoproj.io/compare-result" = "true"
      }
    }
    spec = {
      project = var.argocd_bootstrap_config.project_name
      source = {
        repoURL        = var.argocd_bootstrap_config.root_repo_url
        targetRevision = var.argocd_bootstrap_config.root_target_revision
        path           = var.argocd_bootstrap_config.root_path
      }
      destination = {
        server    = var.argocd_bootstrap_config.root_destination_server
        namespace = var.argocd_bootstrap_config.root_destination_namespace
      }
      syncPolicy = {
        automated = {
          prune    = false
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "PruneLast=true"
        ]
        retry = {
          limit = 5
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.project,
    kubernetes_manifest.repository_secret
  ]
}
