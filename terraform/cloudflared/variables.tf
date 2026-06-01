variable "SERVICE_ACCOUNT_TOKEN" {
  type        = string
  description = "Service account token for the Cloudflare API"
}

variable "CLOUDFLARE_API_TOKEN" {
  type        = string
  description = "API token for the Cloudflare API"
  default = ""
}

variable "account_id" {
  type        = string
  default = ""
}
variable "zone_id" {
  type        = string  
  default = ""
}
variable "domain" {
  type        = string
  default = ""
}
variable "wan_ip" {
  type        = string
  default = ""
}