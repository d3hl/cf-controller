terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3"
    }
  }
}
provider "onepassword" {
  service_account_token = var.SERVICE_ACCOUNT_TOKEN
}
provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}

resource "cloudflare_dns_record" "wildcard" {
  count   = var.enable_public_dns ? 1 : 0
  zone_id = var.zone_id
  name    = "*"
  content = var.wan_ip
  type    = "A"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "host" {
  count   = var.enable_public_dns ? 1 : 0
  zone_id = var.zone_id
  name    = var.domain
  content = var.wan_ip
  type    = "A"
  ttl     = 1
  proxied = true
}

resource "cloudflare_zone_setting" "tls_1_3" {
  count      = var.enable_public_dns ? 1 : 0
  zone_id    = var.zone_id
  setting_id = "tls_1_3"
  value      = "on"
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  count      = var.enable_public_dns ? 1 : 0
  zone_id    = var.zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "ssl" {
  count      = var.enable_public_dns ? 1 : 0
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "strict"
}