# Private network shared across the platform.
#
# Subnet split:
#   backend    10.0.1.0/24  workers / stateful workloads
#   frontend   10.0.2.0/24  edge / ingress nodes
#   management 10.0.3.0/24  gateway, bastion, control plane
#
# Hetzner network zones must match the location of attached servers.
module "network" {
  source = "./modules/hetzner-network"

  name         = "net01"
  cidr         = var.network_cidr
  network_zone = var.hetzner_network_zone

  subnets = {
    backend    = "10.0.1.0/24"
    frontend   = "10.0.2.0/24"
    management = "10.0.3.0/24"
  }
}
