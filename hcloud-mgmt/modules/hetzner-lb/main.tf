resource "hcloud_load_balancer" "this" {
  name               = var.name
  load_balancer_type = var.lb_type
  location           = var.location
}

# Attach the LB to the private network. HCCM uses the private interface to
# talk to backend Pods when HCLOUD_LOAD_BALANCERS_USE_PRIVATE_IP=true is set
# on the HCCM Deployment — that env flips the LB target IP from the node's
# public IPv4 to its private one, which is the only safe option when the
# Hetzner firewall blocks the node's public side.
#
# Background:
#   https://portefolio.calzi.eu/blog/hetzner-hccm-kairos
resource "hcloud_load_balancer_network" "this" {
  load_balancer_id        = hcloud_load_balancer.this.id
  network_id              = var.network_id
  enable_public_interface = true
}
