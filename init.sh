#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$ROOT_DIR/terraform/cloudflared"

cd "$ROOT_DIR"

echo "==> Working directory: $PWD"

if [ ! -d "$TF_DIR" ]; then
  echo "Terraform directory not found: $TF_DIR" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required but was not found in PATH." >&2
  exit 1
fi

echo "==> Terraform version"
terraform version

echo "==> Running Terraform fmt check"
terraform -chdir="$TF_DIR" fmt -check -diff

echo "==> Initializing Terraform without backend"
terraform -chdir="$TF_DIR" init -backend=false -input=false

echo "==> Running Terraform validate"
terraform -chdir="$TF_DIR" validate

echo "==> Baseline verification complete"
echo "Next steps:"
echo "1. Read feature_list.json and claude-progress.md for current status."
echo "2. Pick one unfinished feature and stay in scope."
echo "3. Re-run ./init.sh before claiming done."
echo "4. Use terraform/cloudflared/tf.sh plan only when 1Password and Cloudflare credentials are available."
