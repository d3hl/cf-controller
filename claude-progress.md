# cf-controller Progress

Last Updated: 2026-06-04

## Current State

**Phased Cloudflare apply is complete in HCP** (`ncdv` / `cf-controller-cloudflared`):

| Layer | Resources | Status |
|-------|-----------|--------|
| Mesh | 4 `cloudflare_zero_trust_tunnel_cloudflared_route` | Applied (`run-16bhzLnFCB7nkRMs`) |
| DNS | apex + `*` A → `wan_ip` | Applied (`run-JTNZStKsdHfss3kH`) |
| Zone settings | `ssl`, `tls_1_3`, `automatic_https_rewrites` | Imported (`./tf.sh import zone-settings`) |

`./tf.sh plan verify` → **no changes** (full stack drift check).

**`tf.sh` phases:** `mesh` | `dns` | `zone-settings` | `verify` (split tokens: ZT = `cf-zerotrust-d3hl.site/credential`, DNS = `d3hl.siite-cloudflare config/token`).

Active features: `CF-01-MESH-S2S-TERRAFORM` (Cloudflare control plane done; site-to-site probes pending), `CF-01-REVERSE-PROXY-TERRAFORM` (pending inputs).

## Live Validation (2026-06-04) — Cloudflare API

| Check | Result |
|-------|--------|
| Private routes | 4 routes present: `10.10.10.0/24`, `10.10.30.0/24`, `10.10.50.0/24` on sg-hl-mesh; `10.203.1.0/24` on sg-corp-mesh |
| DNS | `d3hl.site` and `*.d3hl.site` → `202.83.99.15`, proxied |
| `./init.sh` | Passed |
| `./tf.sh plan verify` | No changes |

**Pending (requires Homelab/Office hosts):** ping/trace across mesh per `docs/cloudflare-mesh-network-plan.md` (vmgmt, vsvc, vlab ↔ Office VLAN 101).

**Warning:** `./tf.sh plan mesh` after DNS is in state shows **5 to destroy** (DNS/zone `count = 0` when `enable_public_dns=false`). Do not apply mesh phase after DNS; use `./tf.sh plan verify` instead.

## Apply Evidence (HCP)

| Phase | Run | Result |
|-------|-----|--------|
| mesh apply | `run-16bhzLnFCB7nkRMs` | 4 added |
| dns apply | `run-JTNZStKsdHfss3kH` | 2 DNS added (targeted) |
| zone-settings import | CLI import ×3 | tls_1_3, automatic_https_rewrites, ssl |
| verify plan | (latest verify run) | No changes |
| zone-settings plan | `run-FTHCtyxKdzJjKCKo` | No changes post-import |

## Recommended Next Step

1. **Site-to-site probes** from Homelab and Office (document results in `claude-progress.md`).
2. **`CF-01-REVERSE-PROXY-TERRAFORM`** — approve hostnames/origins, then `./tf.sh` reverse-proxy work.
3. **`CF-01-SECRETS-DOCS`** — `docs/1password-secrets.md` (split ZT vs DNS `op://` paths).
4. HCP cleanup — remove `virtual_environment_*` undeclared workspace vars.

## Blockers

- Site-to-site connectivity not verified from this environment (no Homelab/Office test hosts).
- Reverse proxy blocked on approved `homelab_reverse_proxy_ingress` entries.
