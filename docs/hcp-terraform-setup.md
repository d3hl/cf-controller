# HCP Terraform Setup

Last Updated: 2026-06-02

Use this guide to move `terraform/cloudflared` to an HCP Terraform CLI-driven workspace when the organization and workspace names are ready.

This setup is intentionally not active yet. `terraform/cloudflared/cloud.tf.example` must be copied to `cloud.tf` and filled in before HCP Terraform runs are enabled.

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
| `wan_ip` | no | yes for current DNS resources | Current Terraform uses it for wildcard and apex A records. |
| `enable_mesh_private_routes` | no | when implementing mesh routes | Keep `false` until tunnel IDs are confirmed. |
| `homelab_tunnel_id` | no | when implementing mesh routes or reverse proxy | Existing Homelab Cloudflare Tunnel UUID. |
| `office_tunnel_id` | no | when implementing Office route | Existing Office Cloudflare Tunnel UUID. |
| `cloudflare_tunnel_virtual_network_id` | no | optional | Set only when a non-default virtual network is required. |
| `homelab_vlab_route` | no | optional | Default is `10.10.50.0/24`; use `10.10.50.50/32` only for host-only routing. |
| `enable_homelab_reverse_proxy` | no | when implementing reverse proxy | Keep `false` until ingress entries are approved. |
| `homelab_reverse_proxy_ingress` | no | when implementing reverse proxy | HCL list of ingress objects. Add hostnames and services only after approval. |

### Environment Variables

| Name | Sensitive | Required now | Notes |
|---|---:|---:|---|
| `CLOUDFLARE_API_TOKEN` | yes | yes | Cloudflare provider API token. Use a least-privilege token for DNS, zone settings, Zero Trust tunnels, and private routes. |

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

## Do Not Commit

- `terraform/cloudflared/terraform.tfvars`
- Terraform state files
- Saved plan files
- Plaintext tokens or tunnel secrets
- CLI credential files such as `.terraformrc` or `terraform.rc`
