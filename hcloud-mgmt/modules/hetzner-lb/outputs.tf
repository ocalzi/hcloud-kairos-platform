output "id" {
  description = "Hetzner load balancer ID. HCCM references this when reconciling Service type=LoadBalancer with the `load-balancer.hetzner.cloud/uuid` annotation."
  value       = hcloud_load_balancer.this.id
}

output "ipv4" {
  description = "Public IPv4 of the LB — points DNS at this."
  value       = hcloud_load_balancer.this.ipv4
}

output "private_ipv4" {
  description = "Private IPv4 of the LB inside the attached network."
  value       = hcloud_load_balancer_network.this.ip
}
