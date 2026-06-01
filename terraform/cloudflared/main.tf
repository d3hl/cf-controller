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