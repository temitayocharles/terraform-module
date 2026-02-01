#!/usr/bin/env bash
set -euo pipefail
echo "Running terraform validate for module/sg-dynamic"
terraform init -backend=false >/dev/null
terraform validate
echo "OK"
