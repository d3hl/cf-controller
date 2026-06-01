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
}

resource "cloudflare_dns_record" "wildcard" {
  zone_id = var.zone_id
  name    = "*"
  content = var.wan_ip
  type    = "A"
  ttl     = 1
  proxied = true
}
resource "cloudflare_dns_record" "host" {
  zone_id = var.zone_id
  name    = var.domain
  content = var.wan_ip
  type    = "A"
  ttl     = 1
  proxied = true
}

# Enable TLS 1.3
resource "cloudflare_zone_setting" "tls_1_3" {
  zone_id    = var.zone_id
  setting_id = "tls_1_3"
  value      = "on"
}

# Enable automatic HTTPS rewrites
resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = var.zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

# Set SSL mode to strict
resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "strict"
}