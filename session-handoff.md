# cf-controller Session Handoff

Last Updated: 2026-06-03

## Active Feature

`CF-01-MESH-S2S-TERRAFORM` (in progress). Also open: `CF-01-REVERSE-PROXY-TERRAFORM`, `CF-01-SECRETS-DOCS` (pending).

## Current Objective

Phased apply — **mesh first, then DNS** — after Codex approval per `docs/multi-agent-cloudflare-contract.md`:

1. `./tf.sh apply mesh` — 4 private routes
2. `./tf.sh plan dns` then `./tf.sh apply dns` — 5 DNS/zone resources (keep mesh flags **true** in HCP)

Confirm `homelab_vlab_route` (`10.10.50.0/24` vs `/32`) before mesh apply if still open.

## Current State

- HCP Terraform: org `ncdv`, workspace `cf-controller-cloudflared` (`terraform/cloudflared/cloud.tf`).
- Phased rollout: `enable_public_dns` gates `main.tf`; `./tf.sh [plan|apply] [mesh|dns|all]`.
- Tunnel UUIDs for plans: 1Password `cf-zerotrust-d3hl.site` fields `Tunnel sg-hl-mesh`, `Tunnel sg-corp-mesh` (loaded via `tf.sh` `-var`, not committed).
- DNS pre-check done: no apex/wildcard A; `portal.d3hl.site` CNAME untouched; zone TLS already at target values.
- **No `terraform apply` run yet** — credentialed plans only.
- `./init.sh` passes.

## Files to Read First

| File | Why |
|------|-----|
| `claude-progress.md` | Full evidence table and mesh route matrix |
| `feature_list.json` | Feature status and `nextStep` |
| `docs/hcp-terraform-setup.md` | HCP vars + phased apply table |
| `docs/cloudflare-mesh-network-plan.md` | Route design and live validation gates |
| `terraform/cloudflared/tf.sh` | Phased plan/apply entrypoint |

## Verification Evidence (2026-06-03)

| Command | Result |
|---------|--------|
| `./init.sh` | Passed (incl. after `enable_public_dns` + phased `tf.sh`) |
| `./tf.sh plan` | **5 to add** (mesh off in HCP workspace). Runs: `run-z4tZFz3cbrGkduPZ`, `run-ihz7ExvvnjXDZcry` |
| `terraform plan` + mesh `-var` | **9 to add**. Run: `run-4raRpaQxTuVC3Qbc` |
| `./tf.sh plan mesh` | **4 to add** — vmgmt, vsvc, vlab, office_vlan101 only |
| Cloudflare API DNS list | No apex/wildcard A conflict |

## HCP Workspace (UI apply)

| Phase | `enable_mesh_private_routes` | `enable_public_dns` | Tunnel IDs |
|-------|------------------------------|---------------------|------------|
| 1 — mesh | `true` | `false` | From 1Password or set in workspace |
| 2 — DNS | **`true`** (required) | `true` | unchanged |

CLI `./tf.sh` passes `-var` so plans work even when workspace tfvars are stale.

## Blockers

- Apply blocked on Codex approval (no apply yet).
- HCP workspace may still disable mesh / omit tunnel IDs — use `./tf.sh` phases or align vars before UI apply.
- Reverse proxy: hostnames/origins not approved (`enable_homelab_reverse_proxy=false`).
- HCP undeclared tfvars: `virtual_environment_*` (cleanup recommended).

## Next Session

```bash
cd /home/d3/Github/cf-controller
./init.sh
cd terraform/cloudflared

./tf.sh plan mesh    # expect 4 to add
# After Codex approval:
./tf.sh apply mesh

./tf.sh plan dns     # expect 5 to add (after mesh in state)
# After Codex approval:
./tf.sh apply dns
```

Live checks after apply: `docs/cloudflare-mesh-network-plan.md` validation gates.
