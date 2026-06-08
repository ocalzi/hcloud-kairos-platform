resource "hcloud_network" "this" {
  name     = var.name
  ip_range = var.cidr
}

# One subnet per entry in var.subnets. for_each (not count) so adding/removing
# a single subnet doesn't shift the others' identity in state.
resource "hcloud_network_subnet" "this" {
  for_each = var.subnets

  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = each.value
}
