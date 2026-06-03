locals {
  mesh_private_routes = {
    homelab_vmgmt = {
      enabled   = var.enable_mesh_private_routes && var.homelab_tunnel_id != ""
      tunnel_id = var.homelab_tunnel_id
      network   = "10.10.10.0/24"
      comment   = "Homelab vmgmt"
    }
    homelab_vsvc = {
      enabled   = var.enable_mesh_private_routes && var.homelab_tunnel_id != ""
      tunnel_id = var.homelab_tunnel_id
      network   = "10.10.30.0/24"
      comment   = "Homelab vsvc"
    }
    homelab_vlab = {
      enabled   = var.enable_mesh_private_routes && var.homelab_tunnel_id != ""
      tunnel_id = var.homelab_tunnel_id
      network   = var.homelab_vlab_route
      comment   = "Homelab vlab"
    }
    office_vlan101 = {
      enabled   = var.enable_mesh_private_routes && var.office_tunnel_id != ""
      tunnel_id = var.office_tunnel_id
      network   = "10.203.1.0/24"
      comment   = "Office VLAN 101"
    }
  }

data "onepassword_item" "cf-zerotrust-d3hl.site" {
  vault = var.onepassword_vault
  title = "cf-zerotrust-d3hl.site"
}


  enabled_mesh_private_routes = {
    for name, route in local.mesh_private_routes : name => route
    if route.enabled
  }

  homelab_reverse_proxy_ingress = concat(
    var.homelab_reverse_proxy_ingress,
    [{ service = "http_status:404" }]
  )
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "mesh" {
  for_each = local.enabled_mesh_private_routes

  account_id         = var.account_id
  tunnel_id          = each.value.tunnel_id
  network            = each.value.network
  comment            = each.value.comment
  virtual_network_id = var.cloudflare_tunnel_virtual_network_id == "" ? null : var.cloudflare_tunnel_virtual_network_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab_reverse_proxy" {
  count = var.enable_homelab_reverse_proxy && var.homelab_tunnel_id != "" && length(var.homelab_reverse_proxy_ingress) > 0 ? 1 : 0

  account_id = var.account_id
  tunnel_id  = data.onepassword_item.cf-zerotrust-d3hl.site.item.uuid
  source     = "cloudflare"

  config = {
    ingress = local.homelab_reverse_proxy_ingress
  }
}
