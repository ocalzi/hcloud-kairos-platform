output "network_id" {
  description = "ID of the created hcloud_network — feed to hcloud_server, hcloud_server_network, and (if you add HCCM) hcloud_load_balancer_network attachments."
  value       = hcloud_network.this.id
}

output "subnet_ids" {
  description = "Map of subnet name -> hcloud_network_subnet ID. Look up by name when attaching a server."
  value       = { for k, s in hcloud_network_subnet.this : k => s.id }
}
