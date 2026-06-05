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
Usage: ./tf.sh [plan|apply|import] [mesh|dns|zone-settings|verify|all]

  mesh           — 4 private routes only (enable_public_dns=false; do not apply after DNS in state)
  dns            — apex/wildcard A records (mesh flags stay on)
  zone-settings  — import/apply tls_1_3, automatic_https_rewrites, ssl (ZT token)
  verify         — plan with mesh + DNS enabled (drift check; expect no changes)
  all            — not supported (use mesh, dns, zone-settings)

Examples:
  ./tf.sh plan mesh
  ./tf.sh apply mesh
  ./tf.sh plan dns
  ./tf.sh apply dns
  ./tf.sh import zone-settings

Env: TF_PHASE=mesh|dns|zone-settings|all overrides the phase argument.
EOF
}

export TF_VAR_SERVICE_ACCOUNT_TOKEN="$(op read op://d3HLPRV/iu2lj435cprjpf3ddpjnfuyqni/Token)"

# Zero Trust (mesh routes) vs Zone DNS/settings use different tokens in 1Password.
CF_TOKEN_ZT="$(op read 'op://d3HLPRV/cf-zerotrust-d3hl.site/credential')"
CF_TOKEN_DNS="$(op read 'op://d3HLPRV/d3hl.siite-cloudflare config/token')"
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
    plan|apply|import) CMD="$arg" ;;
    mesh|dns|zone-settings|verify|all) PHASE="$arg" ;;
    -h|--help) usage; exit 0 ;;
    *) ARGS+=("$arg") ;;
  esac
done

PHASE_VARS=()
case "$PHASE" in
  mesh)
    export TF_VAR_CLOUDFLARE_API_TOKEN="${CF_TOKEN_ZT}"
    export CLOUDFLARE_API_TOKEN="${TF_VAR_CLOUDFLARE_API_TOKEN}"
    PHASE_VARS=(
      -var="enable_mesh_private_routes=true"
      -var="enable_public_dns=false"
      "${MESH_TUNNEL_VARS[@]}"
    )
    ;;
  dns)
    export TF_VAR_CLOUDFLARE_API_TOKEN="${CF_TOKEN_DNS}"
    export CLOUDFLARE_API_TOKEN="${TF_VAR_CLOUDFLARE_API_TOKEN}"
    # DNS token cannot refresh ZT routes; skip refresh and target DNS records only.
    ARGS+=(-refresh=false)
    if [ "$CMD" = "apply" ]; then
      ARGS+=(
        -target='cloudflare_dns_record.wildcard[0]'
        -target='cloudflare_dns_record.host[0]'
      )
    fi
    PHASE_VARS=(
      -var="enable_mesh_private_routes=true"
      -var="enable_public_dns=true"
      "${MESH_TUNNEL_VARS[@]}"
    )
    ;;
  zone-settings)
    export TF_VAR_CLOUDFLARE_API_TOKEN="${CF_TOKEN_ZT}"
    export CLOUDFLARE_API_TOKEN="${TF_VAR_CLOUDFLARE_API_TOKEN}"
    ARGS+=(-refresh=false)
    PHASE_VARS=(
      -var="enable_mesh_private_routes=true"
      -var="enable_public_dns=true"
      "${MESH_TUNNEL_VARS[@]}"
    )
    if [ "$CMD" = "import" ]; then
      Z="${TF_VAR_zone_id}"
      for SETTING in tls_1_3 automatic_https_rewrites ssl; do
        echo "==> import cloudflare_zone_setting.${SETTING}[0] ${Z}/${SETTING}" >&2
        terraform import -input=false "${PHASE_VARS[@]}" \
          "cloudflare_zone_setting.${SETTING}[0]" "${Z}/${SETTING}"
      done
      exit 0
    fi
    if [ "$CMD" = "apply" ]; then
      ARGS+=(
        -target='cloudflare_zone_setting.tls_1_3[0]'
        -target='cloudflare_zone_setting.automatic_https_rewrites[0]'
        -target='cloudflare_zone_setting.ssl[0]'
      )
    fi
    ;;
  verify)
    export TF_VAR_CLOUDFLARE_API_TOKEN="${CF_TOKEN_ZT}"
    export CLOUDFLARE_API_TOKEN="${TF_VAR_CLOUDFLARE_API_TOKEN}"
    PHASE_VARS=(
      -var="enable_mesh_private_routes=true"
      -var="enable_public_dns=true"
      "${MESH_TUNNEL_VARS[@]}"
    )
    if [ "$CMD" != "plan" ]; then
      echo "phase=verify supports plan only (read-only drift check)." >&2
      exit 1
    fi
    ;;
  all)
    echo "phase=all requires a single token with both ZT and DNS; use mesh, dns, zone-settings, verify instead." >&2
    exit 1
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
