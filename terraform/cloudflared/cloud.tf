# Copy this file to cloud.tf after choosing the HCP Terraform organization and workspace.
# Then run:
#   terraform login
#   terraform -chdir=terraform/cloudflared init
#
# If local state already exists and should move to HCP Terraform, review the state migration prompt carefully.

terraform {
  cloud {
    organization = "ncdv"
    hostname     = "app.terraform.io"

    workspaces {
      name = "cf-controller-cloudflared"
    }
  }
}
