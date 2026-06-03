variable "SERVICE_ACCOUNT_TOKEN" {
  type        = string
  description = "Service account token for the Cloudflare API"
}

variable "CLOUDFLARE_API_TOKEN" {
  type        = string
  description = "API token for the Cloudflare API"
  default     = ""
}

variable "account_id" {
  type    = string
  default = ""
}
variable "zone_id" {
  type    = string
  default = ""
}
variable "domain" {
  type    = string
  default = ""
}
variable "wan_ip" {
  type    = string
  default = ""
}

variable "enable_mesh_private_routes" {
  type        = bool
  description = "Create Cloudflare Zero Trust private routes for the Homelab and Office mesh when tunnel IDs are supplied."
  default     = false
}

variable "homelab_tunnel_id" {
  type        = string
  description = "Existing Cloudflare Tunnel ID for the Homelab connector. Leave empty until imported or created intentionally."
  default     = ""
}

variable "office_tunnel_id" {
  type        = string
  description = "Existing Cloudflare Tunnel ID for the Office connector. Leave empty until imported or created intentionally."
  default     = ""
}

variable "cloudflare_tunnel_virtual_network_id" {
  type        = string
  description = "Optional Cloudflare Zero Trust virtual network ID for these private routes."
  default     = ""
}

variable "homelab_vlab_route" {
  type        = string
  description = "Cloudflare private route for Homelab vlab. Default routes the full VLAN 50 subnet; set to 10.10.50.50/32 for host-only routing if required."
  default     = "10.10.50.0/24"
}

variable "enable_homelab_reverse_proxy" {
  type        = bool
  description = "Create Homelab Cloudflare Tunnel ingress configuration when reverse-proxy ingress entries are supplied."
  default     = false
}

variable "homelab_reverse_proxy_ingress" {
  type = list(object({
    hostname = optional(string)
    path     = optional(string)
    service  = string
  }))
  description = "Cloudflare Tunnel ingress entries for local Homelab resources. A terminal 404 rule is appended automatically."
  default     = []
}

variable "onepassword_vault" {
  type        = string
  description = "1Password vault containing secrets"
  default     = "d3HLPRV"
}