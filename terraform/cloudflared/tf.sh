#!/bin/bash
# Phased apply: mesh private routes first, then public DNS/zone settings.
#   ./tf.sh plan mesh && ./tf.sh apply mesh
#   ./tf.sh plan dns  && ./tf.sh apply dns
#   ./tf.sh plan all  # both phases in one plan (not recommended for first rollout)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

usage() {
  cat <<'EOF'
Usage: ./tf.sh [plan|apply] [mesh|dns|all]

  mesh  — 4 private routes only (enable_public_dns=false)
  dns   — apex/wildcard + zone settings only (mesh flags stay on; no route destroy)
  all   — mesh + dns in one run

Examples:
  ./tf.sh plan mesh
  ./tf.sh apply mesh
  ./tf.sh plan dns
  ./tf.sh apply dns

Env: TF_PHASE=mesh|dns|all overrides the phase argument.
EOF
}

export TF_VAR_SERVICE_ACCOUNT_TOKEN="$(op read op://d3HLPRV/iu2lj435cprjpf3ddpjnfuyqni/Token)"
export CLOUDFLARE_API_TOKEN="$(op read 'op://d3HLPRV/dbj2f4rurkzkndb2cbuqeervcu/credential')"
export TF_VAR_account_id="$(op read 'op://d3HLPRV/dbj2f4rurkzkndb2cbuqeervcu/Account ID')"
export TF_VAR_zone_id="$(op read 'op://d3HLPRV/dbj2f4rurkzkndb2cbuqeervcu/Zone ID')"

HL_ID="${TF_VAR_homelab_tunnel_id:-$(op read 'op://d3HLPRV/cf-zerotrust-d3hl.site/Tunnel sg-hl-mesh')}"
OFF_ID="${TF_VAR_office_tunnel_id:-$(op read 'op://d3HLPRV/cf-zerotrust-d3hl.site/Tunnel sg-corp-mesh')}"

MESH_TUNNEL_VARS=(
  -var="homelab_tunnel_id=${HL_ID}"
  -var="office_tunnel_id=${OFF_ID}"
)

CMD="plan"
PHASE="${TF_PHASE:-all}"
ARGS=()

for arg in "$@"; do
  case "$arg" in
    plan|apply) CMD="$arg" ;;
    mesh|dns|all) PHASE="$arg" ;;
    -h|--help) usage; exit 0 ;;
    *) ARGS+=("$arg") ;;
  esac
done

PHASE_VARS=()
case "$PHASE" in
  mesh)
    PHASE_VARS=(
      -var="enable_mesh_private_routes=true"
      -var="enable_public_dns=false"
      "${MESH_TUNNEL_VARS[@]}"
    )
    ;;
  dns)
    # Keep mesh enabled so phase 1 routes are not destroyed.
    PHASE_VARS=(
      -var="enable_mesh_private_routes=true"
      -var="enable_public_dns=true"
      "${MESH_TUNNEL_VARS[@]}"
    )
    ;;
  all)
    PHASE_VARS=(
      -var="enable_mesh_private_routes=true"
      -var="enable_public_dns=true"
      "${MESH_TUNNEL_VARS[@]}"
    )
    ;;
  *)
    echo "Unknown phase: $PHASE (use mesh, dns, or all)" >&2
    usage
    exit 1
    ;;
esac

if [ ! -d .terraform ]; then
  terraform init -input=false
fi

echo "==> phase=${PHASE} command=${CMD}" >&2
terraform "$CMD" "${ARGS[@]}" "${PHASE_VARS[@]}"
