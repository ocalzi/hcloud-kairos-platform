output "id" {
  description = "Hetzner server ID."
  value       = hcloud_server.this.id
}

output "ipv4_address" {
  description = "Public IPv4 of the server."
  value       = hcloud_server.this.ipv4_address
}

output "private_ipv4_address" {
  description = "Private IPv4 assigned in the subnet."
  value       = hcloud_server_network.this.ip
}

output "status" {
  description = "Hetzner-reported power status (running, off, ...). After Kairos install completes, expect 'off' until hcloud-postinstall powers it back on."
  value       = hcloud_server.this.status
}
