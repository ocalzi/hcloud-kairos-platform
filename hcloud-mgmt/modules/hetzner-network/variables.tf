variable "name" {
  description = "Name of the Hetzner private network (e.g. net01)."
  type        = string
}

variable "cidr" {
  description = "IP range of the network. Hetzner accepts a single CIDR per network; subnets carve it up."
  type        = string
}

variable "network_zone" {
  description = "Hetzner network zone (eu-central, us-east, us-west, ap-southeast). Must match the location of the servers attached to it."
  type        = string
}

variable "subnets" {
  description = "Map of subnet name -> CIDR. Each entry becomes one hcloud_network_subnet inside the parent network."
  type        = map(string)
}
