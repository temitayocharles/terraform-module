# Argo CD Bootstrap Module

## Purpose
Install Argo CD into an existing Kubernetes cluster and hand off platform ownership to the GitOps root application.

## Boundary
This module is intentionally minimal. It manages only:
- the `argocd` namespace
- the Argo CD Helm release
- Argo CD repository credentials
- the bootstrap `AppProject` required by the root app
- the root `Application` that points to `platform-gitops`

It does not manage platform services, workloads, Vault roles, or ConfigMaps. Those remain owned by GitOps.

## Input Variables
- `argocd_bootstrap_config`
  - enable/disable bootstrap
  - Argo CD chart/release settings
  - bootstrap project definition
  - root application definition
  - repository credentials metadata
- `repo_passwords`
  - sensitive password/token map keyed by repository name

## Outputs
- bootstrap namespace
- Helm release name
- root application name
- created repository secret names
