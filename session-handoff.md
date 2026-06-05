# cf-controller Session Handoff

Last Updated: 2026-06-04

## Active Feature

`CF-01-MESH-S2S-TERRAFORM` — Cloudflare control plane **applied**; site-to-site live probes pending. Next feature: `CF-01-REVERSE-PROXY-TERRAFORM`.

## Current State

- HCP: `ncdv` / `cf-controller-cloudflared`
- **9 resources in state:** 4 mesh routes, 2 DNS, 3 zone settings (imported)
- `./tf.sh plan verify` → no changes
- API validation 2026-06-04: 4 private routes + apex/wildcard A confirmed

## tf.sh phases

| Phase | Token | Purpose |
|-------|-------|---------|
| `mesh` | cf-zerotrust | 4 private routes (`enable_public_dns=false`) |
| `dns` | d3hl.siite-cloudflare `token` | apex + wildcard A (`-refresh=false`, targeted apply) |
| `zone-settings` | cf-zerotrust | import/plan/apply zone TLS settings |
| `verify` | cf-zerotrust | **plan only** — full drift check |

Do **not** `./tf.sh apply mesh` after DNS is in state (plan mesh shows 5 destroy).

## Next Session

```bash
cd /home/d3/Github/cf-controller
./init.sh
cd terraform/cloudflared
./tf.sh plan verify   # expect no changes
```

Then: site-to-site probes per `docs/cloudflare-mesh-network-plan.md`, or start reverse-proxy inputs.

## Blockers

- Homelab ↔ Office reachability tests not run from agent environment
- Reverse-proxy hostnames/origins not approved
