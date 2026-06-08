variable "name" {
  description = "Name for the hcloud_load_balancer."
  type        = string
}

variable "location" {
  description = "Hetzner location slug. Must match the location of the target servers (HCCM reconciles in-zone)."
  type        = string
}

variable "network_id" {
  description = "Private network ID to attach the LB to. Required to talk to backend Pods/Services over the private side."
  type        = string
}

variable "lb_type" {
  description = "Hetzner LB tier: lb11 (cheapest, 25 services) / lb21 / lb31."
  type        = string
  default     = "lb11"
}
