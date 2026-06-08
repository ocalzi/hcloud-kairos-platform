output "fqdn" {
  description = "Full DNS name pointing at the gateway."
  value       = "${var.subdomain}.${var.zone}"
}

output "target" {
  description = "IPv4 the record resolves to."
  value       = ovh_domain_zone_record.gateway.target
}
