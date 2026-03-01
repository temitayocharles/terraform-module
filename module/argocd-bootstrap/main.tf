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

  project_manifest = {
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

  root_application_manifest = {
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
}

resource "helm_release" "argocd" {
  count = local.enabled ? 1 : 0

  name             = local.release_name
  repository       = var.argocd_bootstrap_config.helm_repo
  chart            = "argo-cd"
  version          = var.argocd_bootstrap_config.chart_version
  namespace        = local.namespace
  create_namespace = true
  wait             = true
  atomic           = true
  timeout          = 600
  cleanup_on_fail  = true
  values           = local.helm_values
}

resource "kubernetes_secret_v1" "repository_secret" {
  for_each = local.enabled ? local.repo_credentials : {}

  metadata {
    name      = "argocd-repo-${each.key}"
    namespace = local.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    name     = base64encode(each.value.name)
    type     = base64encode(try(each.value.type, "git"))
    url      = base64encode(each.value.url)
    username = base64encode(each.value.username)
    password = base64encode(lookup(var.repo_passwords, each.key, ""))
  }

  depends_on = [helm_release.argocd]
}



resource "terraform_data" "argocd_crd_bootstrap" {
  count = local.enabled ? 1 : 0

  triggers_replace = {
    project_manifest          = sha256(yamlencode(local.project_manifest))
    root_application_manifest = sha256(yamlencode(local.root_application_manifest))
    auth_mode                 = var.kubectl_config.auth_mode
    kubeconfig_path           = try(var.kubectl_config.kubeconfig_path, "")
    kubeconfig_context        = try(var.kubectl_config.kubeconfig_context, "")
    host                      = try(var.kubectl_config.host, null) == null ? "" : var.kubectl_config.host
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
      set -euo pipefail
      tmpdir=$(mktemp -d)
      trap 'rm -rf "$tmpdir"' EXIT

      if [ "${var.kubectl_config.auth_mode}" = "kubeconfig" ]; then
        export KUBECONFIG="${try(var.kubectl_config.kubeconfig_path, "")}" 
        KUBECTL_CONTEXT_ARG=""
        if [ -n "${try(var.kubectl_config.kubeconfig_context, "")}" ]; then
          KUBECTL_CONTEXT_ARG="--context ${try(var.kubectl_config.kubeconfig_context, "")}" 
        fi
      else
        cat > "$tmpdir/kubeconfig" <<'KUBECONFIG'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: ${try(var.kubectl_config.host, null) == null ? "" : var.kubectl_config.host}
    certificate-authority-data: ${base64encode(try(var.kubectl_config.cluster_ca_certificate, null) == null ? "" : var.kubectl_config.cluster_ca_certificate)}
  name: bootstrap-cluster
contexts:
- context:
    cluster: bootstrap-cluster
    user: bootstrap-user
  name: bootstrap-context
current-context: bootstrap-context
users:
- name: bootstrap-user
  user:
    token: ${try(var.kubectl_config.token, null) == null ? "" : var.kubectl_config.token}
KUBECONFIG
        export KUBECONFIG="$tmpdir/kubeconfig"
        KUBECTL_CONTEXT_ARG=""
      fi

      cat > "$tmpdir/project.yaml" <<'YAML'
${yamlencode(local.project_manifest)}
YAML
      cat > "$tmpdir/root-application.yaml" <<'YAML'
${yamlencode(local.root_application_manifest)}
YAML

      kubectl $KUBECTL_CONTEXT_ARG apply -f "$tmpdir/project.yaml"
      kubectl $KUBECTL_CONTEXT_ARG apply -f "$tmpdir/root-application.yaml"
    EOT
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_secret_v1.repository_secret
  ]
}
