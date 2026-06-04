# HCP Terraform Setup

Last Updated: 2026-06-03

Use this guide for the HCP Terraform CLI-driven workspace backing `terraform/cloudflared`.

**Active workspace (2026-06-03):** organization `ncdv`, workspace `cf-controller-cloudflared` in `terraform/cloudflared/cloud.tf`. Run `terraform init` in that directory before the first credentialed plan.

`terraform/cloudflared/cloud.tf.example` remains a template for new environments.

## Context7 Source Check

Context7 was used for current HCP Terraform guidance. The relevant setup model is:

- Add a Terraform `cloud` block with `organization`, optional `hostname = "app.terraform.io"`, and `workspaces { name = "..." }`.
- Authenticate the CLI with `terraform login`.
- Run `terraform init` after the cloud block is present.
- Put sensitive values in HCP Terraform workspace variables, not in committed files.

## Workspace Choice

Recommended workspace:

```text
Organization: ncdv
Workspace: cf-controller-cloudflared
Execution mode: Remote or local, depending on whether HCP Terraform can access required provider credentials
Apply method: Manual
Terraform version: match local Terraform v1.15.5 unless intentionally upgraded
```

Manual apply is recommended because this repo manages Cloudflare DNS, zone settings, private network routes, and tunnel reverse-proxy configuration.

## Enable HCP Terraform

From the repo root:

```bash
cd /home/d3/Github/cf-controller
cp terraform/cloudflared/cloud.tf.example terraform/cloudflared/cloud.tf
```

Edit `terraform/cloudflared/cloud.tf`:

```hcl
terraform {
  cloud {
    organization = "YOUR_HCP_TERRAFORM_ORG"
    hostname     = "app.terraform.io"

    workspaces {
      name = "cf-controller-cloudflared"
    }
  }
}
```

Then authenticate and initialize:

```bash
terraform login
terraform -chdir=terraform/cloudflared init
```

If Terraform prompts to migrate local state to HCP Terraform, stop and review the current tracked state files before approving. Do not commit state file changes as part of the migration.

## HCP Workspace Variables

Set these as HCP Terraform workspace variables. Mark sensitive values as sensitive.

### Terraform Variables

| Name | Sensitive | Required now | Notes |
|---|---:|---:|---|
| `SERVICE_ACCOUNT_TOKEN` | yes | yes | 1Password provider service account token. Prefer HCP sensitive variable over local `op read` for remote runs. |
| `account_id` | no | yes | Cloudflare account ID. |
| `zone_id` | no | yes | Cloudflare zone ID for `domain`. |
| `domain` | no | yes | Example: `d3hl.site`. |
| `wan_ip` | no | yes for phase-2 DNS | Required when `enable_public_dns = true`. |
| `enable_public_dns` | no | phase 2 only | Keep `false` until mesh routes are applied. Phase 2 sets `true` for apex/wildcard + zone settings. |
| `enable_mesh_private_routes` | no | phase 1 | Set `true` for mesh. `tf.sh` passes `-var` from 1Password (`cf-zerotrust-d3hl.site`: `Tunnel sg-hl-mesh`, `Tunnel sg-corp-mesh`) so CLI runs are not blocked by stale workspace tfvars. |
| `homelab_tunnel_id` | no | when implementing mesh routes or reverse proxy | Homelab tunnel UUID (`sg-hl-mesh` in 1Password). |
| `office_tunnel_id` | no | when implementing Office route | Office tunnel UUID (`sg-corp-mesh` in 1Password). |
| `cloudflare_tunnel_virtual_network_id` | no | optional | Set only when a non-default virtual network is required. |
| `homelab_vlab_route` | no | optional | Default is `10.10.50.0/24`; use `10.10.50.50/32` only for host-only routing. |
| `enable_homelab_reverse_proxy` | no | when implementing reverse proxy | Keep `false` until ingress entries are approved. |
| `homelab_reverse_proxy_ingress` | no | when implementing reverse proxy | HCL list of ingress objects. Add hostnames and services only after approval. |

### Environment Variables

| Name | Sensitive | Required now | Notes |
|---|---:|---:|---|
| `CLOUDFLARE_API_TOKEN` | yes | yes | Cloudflare provider API token (workspace **environment variable**). Required for remote apply; `tf.sh` also sets `TF_VAR_CLOUDFLARE_API_TOKEN` for CLI-driven runs. Least-privilege: DNS, zone settings, Zero Trust tunnels, private routes. |

## Reverse Proxy Variable Example

Use HCL format for the `homelab_reverse_proxy_ingress` Terraform variable in HCP Terraform:

```hcl
[
  {
    hostname = "resource.example.com"
    service  = "https://10.10.30.10:443"
  }
]
```

The Terraform scaffold appends a terminal `http_status:404` ingress rule automatically.

## Validation Commands

Before enabling HCP Terraform:

```bash
cd /home/d3/Github/cf-controller
./init.sh
terraform -chdir=terraform/cloudflared fmt -check -diff
terraform -chdir=terraform/cloudflared validate
```

After `cloud.tf` is created and HCP variables are set:

```bash
terraform -chdir=terraform/cloudflared init
terraform -chdir=terraform/cloudflared plan
```

Do not run `terraform apply` until Codex has reviewed Composer implementation output and DeepSeek verification evidence.

## Phased apply (mesh first, then DNS)

| Phase | HCP / tfvars | Command | Expected plan |
|-------|----------------|---------|-----------------|
| 1 — mesh | `enable_mesh_private_routes=true`, `enable_public_dns=false`, tunnel IDs set | `./tf.sh plan mesh` then `./tf.sh apply mesh` | **4 to add** — private routes only |
| 2 — DNS | `enable_public_dns=true`, keep mesh flags **true** (do not disable mesh or routes will be destroyed) | `./tf.sh plan dns` then `./tf.sh apply dns` | **5 to add** — DNS + zone settings |

After phase 1, set `enable_public_dns=true` in the HCP workspace before phase-2 UI apply, or use `./tf.sh apply dns` from the CLI.

## 2026-06-03 plan notes

- Remote plan with mesh flags disabled: **5 to add** (wildcard + apex `cloudflare_dns_record`, three `cloudflare_zone_setting` resources). No mesh routes in plan until `enable_mesh_private_routes = true` and tunnel IDs are set.
- Remote plan with mesh `-var` from `tf.sh`: **9 to add** (4 `cloudflare_zero_trust_tunnel_cloudflared_route` + 5 DNS/zone). HCP workspace tfvars can disable mesh unless CLI `-var` is used.
- Remove undeclared HCP workspace variables (`virtual_environment_username`, `virtual_environment_api_token`, and similar) or add matching `variable` blocks to silence warnings.

## DNS pre-apply check (2026-06-03)

Live zone `d3hl.site` had **no** apex or wildcard **A** records (safe to create). Existing records: `portal.d3hl.site` CNAME → `gateway.agents.cloudflare.com` (unchanged by this stack); apex TXT for domain verification. Zone settings `ssl`, `tls_1_3`, and `automatic_https_rewrites` already match Terraform targets — apply will adopt them into state, not change live values.

## Do Not Commit

- `terraform/cloudflared/terraform.tfvars`
- Terraform state files
- Saved plan files
- Plaintext tokens or tunnel secrets
- CLI credential files such as `.terraformrc` or `terraform.rc`
