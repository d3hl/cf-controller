# Cloudflare Mesh Network Plan

Last Updated: 2026-06-03

## Goal

Plan the Cloudflare side of a site-to-site mesh between the Homelab Proxmox SDN networks and the Office VLAN 101 network, then publish selected Homelab resources through Cloudflare Tunnel as reverse-proxied public hostnames.

This is a planning and input-configuration artifact. It does not authorize live Cloudflare mutation.

Current implementation status: `terraform/cloudflared/mesh.tf` contains disabled-by-default Terraform scaffolding for the private routes and Homelab reverse-proxy tunnel config. No resources are created until the enable flags and required IDs are supplied.

HCP Terraform is active: `terraform/cloudflared/cloud.tf` (org `ncdv`, workspace `cf-controller-cloudflared`). See `docs/hcp-terraform-setup.md`. Mesh routes are implemented in `mesh.tf` but disabled until tunnel IDs and `enable_mesh_private_routes` are set in workspace variables.

## Context7 Source Check

Context7 was used against `/cloudflare/terraform-provider-cloudflare` for the Cloudflare Terraform provider v5 resource model. The relevant resources for the next implementation pass are:

- `cloudflare_zero_trust_tunnel_cloudflared`
- `cloudflare_zero_trust_tunnel_cloudflared_config`
- `cloudflare_zero_trust_tunnel_cloudflared_route`
- `cloudflare_zero_trust_tunnel_cloudflared_virtual_network`
- `cloudflare_zero_trust_network_hostname_route`
- `cloudflare_dns_record`

Keep the current repo workflow: static `fmt`, `init -backend=false`, and `validate` before credentialed `plan`; no `apply` without explicit user and Codex final approval.

## Sites and Routes

### Site A: Homelab

Authoritative Proxmox SDN state lives in `/home/d3/Github/d3hl-managed-proxmox`.

| Network | Requested input | Planned route | Notes |
| --- | ---: | ---: | --- |
| `vmgmt` | `10.10.10.0/24` | `10.10.10.0/24` | Proxmox management; FortiGate gateway is `10.10.10.2`. |
| `vsvc` | `10.10.30.0/24` | `10.10.30.0/24` | VM subnet, Fortigate gateway is `10.10.30.2` |
| `vlab` | `10.10.50.0/24` | `10.10.50.0/24` | Guest subnet, Fortigate gateway is `10.10.50.2` |

### Site B: Office

| Network | Planned route | Notes |
| --- | ---: | --- |
| VLAN 101 | `10.203.1.0/24` | Office-side route; requires an Office connector/tunnel and local routing/firewall validation. |

## Target Architecture

Use Cloudflare Zero Trust private network routing as the control plane:

1. Create or import a Homelab Cloudflare Tunnel connector.
2. Create or import an Office Cloudflare Tunnel connector.
3. Place both connectors in the intended Zero Trust virtual network, unless Composer finds an existing Cloudflare virtual network should be reused.
4. Route Homelab CIDRs through the Homelab tunnel:
   - `10.10.10.0/24`
   - `10.10.30.0/24`
   - `10.10.50.0/24`
5. Route Office CIDR through the Office tunnel:
   - `10.203.1.0/24`
6. Validate that local site gateways know how to return traffic to the Cloudflare connector path. If LAN hosts are expected to communicate without WARP installed locally, the site routers/firewalls must have route and policy support for the connector path.

## Terraform Implementation Shape

Composer should turn on this scaffold only after Codex approves concrete inputs.

Required inputs:

- Cloudflare account ID.
- Zone ID and domain for public reverse-proxy records.
- Homelab tunnel ID or approved name/secret source for tunnel creation: `var.homelab_tunnel_id`.
- Office tunnel ID or approved name/secret source for tunnel creation: `var.office_tunnel_id`.
- Virtual network ID or approved name for a new virtual network: `var.cloudflare_tunnel_virtual_network_id`.
- Public hostnames and local origin services for reverse proxy.
- HCP Terraform organization and workspace, if remote runs will be used.

Implemented scaffold:

```hcl
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "mesh" {
  for_each = local.enabled_mesh_private_routes

  account_id         = var.account_id
  tunnel_id          = each.value.tunnel_id
  network            = each.value.network
  comment            = each.value.comment
  virtual_network_id = var.cloudflare_tunnel_virtual_network_id == "" ? null : var.cloudflare_tunnel_virtual_network_id
}
```

Reverse proxy hostnames are modeled with `cloudflare_zero_trust_tunnel_cloudflared_config` ingress entries once hostnames and origin services are known:

```hcl
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab_reverse_proxy" {
  count = var.enable_homelab_reverse_proxy && var.homelab_tunnel_id != "" && length(var.homelab_reverse_proxy_ingress) > 0 ? 1 : 0

  account_id = var.account_id
  tunnel_id  = var.homelab_tunnel_id
  source     = "cloudflare"

  config = {
    ingress = local.homelab_reverse_proxy_ingress
  }
}
```

DNS records for public hostnames should be reviewed during implementation. Do not replace the existing wildcard or apex records until Composer produces a plan showing no conflict.

## Reverse Proxy Input Matrix

Fill this before Terraform implementation:

| Public hostname | Site | Origin service | Access policy needed | Notes |
| --- | --- | --- | --- | --- |
| TBD | Homelab | TBD | TBD | Candidate local resources must be named before config is generated. |

## Agent Assignment

Follow `docs/multi-agent-cloudflare-contract.md`.

- Codex owns this plan, the input matrix, acceptance criteria, and final approval.
- Composer owns Terraform configuration review, debate, and implementation after missing inputs are supplied.
- DeepSeek owns static verification, optional credentialed plan evidence, and handoff back to Codex.

## Validation Gates

Non-live checks:

```bash
cd /home/d3/Github/cf-controller
./init.sh
terraform -chdir=terraform/cloudflared fmt -check -diff
terraform -chdir=terraform/cloudflared init -backend=false -input=false
terraform -chdir=terraform/cloudflared validate
```

Credentialed plan, only after inputs are complete (phased: mesh first, then DNS):

```bash
cd /home/d3/Github/cf-controller/terraform/cloudflared
./tf.sh plan mesh   # 4 private routes
./tf.sh apply mesh  # after Codex approval
./tf.sh plan dns    # 5 DNS/zone resources; mesh stays enabled in config
./tf.sh apply dns   # after Codex approval
```

Live validation after approved apply:

- Cloudflare routes show Homelab CIDRs on the Homelab tunnel and `10.203.1.0/24` on the Office tunnel.
- Homelab host can reach an allowed Office VLAN 101 test IP.
- Office host can reach allowed Homelab test IPs in `vmgmt`, `vsvc`, and `vlab`.
- Public reverse-proxy hostname resolves through Cloudflare and reaches the selected local origin.
- No plaintext secrets, local `*.tfvars`, Terraform state, or plan artifacts are committed.

## Open Inputs and Risks

- Office connector placement and tunnel ID are not yet known.
- Public reverse-proxy hostnames and local origin services are not yet named.
- The requested `vlab` value `10.10.50.50/24` is treated as the subnet `10.10.50.0/24`; confirm if this should instead be a host-only route.
- True LAN-to-LAN behavior depends on local routing and firewall policy at both sites, not only Cloudflare routes.
- Current Terraform state and `tfvars` artifacts are tracked existing repo state; do not modify them as part of planning work.
