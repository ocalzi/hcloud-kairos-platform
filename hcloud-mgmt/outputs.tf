output "gateway_public_ip" {
  description = "Public IPv4 of the gateway node. Point external DNS here for ingress traffic."
  value       = module.gateway.ipv4_address
}

output "gateway_private_ip" {
  description = "Private IPv4 of the gateway inside the management subnet. Used as the next-hop for the default route on other subnets."
  value       = module.gateway.private_ipv4_address
}

output "network_id" {
  description = "ID of the hcloud_network — feed downstream projects (workload Terraform, or HCCM if you later add it for cluster-managed LoadBalancers)."
  value       = module.network.network_id
}
