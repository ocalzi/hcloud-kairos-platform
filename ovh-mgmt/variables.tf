variable "ovh_endpoint" {
  description = "OVH API endpoint slug (ovh-eu, ovh-us, ovh-ca, ...). Matches the region where the account/zone lives."
  type        = string
  default     = "ovh-eu"
}

variable "zone" {
  description = "OVH DNS zone (the apex domain) the showcase publishes records into."
  type        = string
}

variable "subdomain" {
  description = "Subdomain attached to the gateway public IP. Final FQDN is `<subdomain>.<zone>`."
  type        = string
  default     = "showcase"
}

variable "gateway_ipv4" {
  description = "Public IPv4 of the gateway VM. Fed from hcloud-mgmt's `gateway_public_ipv4` output after the first `tofu apply`."
  type        = string
}

variable "ttl" {
  description = "DNS TTL in seconds. 60s is fine for a tear-down-able showcase, 3600s for stable demos."
  type        = number
  default     = 60
}
