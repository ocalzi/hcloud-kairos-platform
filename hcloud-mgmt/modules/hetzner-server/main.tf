# Resolve the throwaway disk image by name + architecture. Hetzner ages older
# Debian releases out of the catalog as new ones become default; resolving via
# data source means we don't break the day debian-N -1 disappears. The disk
# image is wiped on first boot by the Kairos auto-installer anyway.
data "hcloud_image" "boot" {
  name              = "debian-13"
  with_architecture = startswith(var.server_type, "cax") ? "arm" : "x86"
}

resource "hcloud_server" "this" {
  name        = var.name
  server_type = var.server_type
  location    = var.location
  image       = data.hcloud_image.boot.id
  iso         = var.iso_id
  user_data   = var.user_data
  ssh_keys    = [var.ssh_key_id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  lifecycle {
    # Re-rendering user_data shouldn't replace a running node — Kairos applies
    # config on boot, not on cloud-init refresh. Force a rebuild with
    # `tofu taint <addr>` when you actually want the new config to apply.
    ignore_changes = [image, user_data]
  }
}

# Attach the server to its subnet in a standalone resource. Setting the
# network{} block on hcloud_server itself fights with hcloud_server_network
# when both network_id and subnet_id are present.
resource "hcloud_server_network" "this" {
  server_id = hcloud_server.this.id
  subnet_id = var.subnet_id
  ip        = var.private_ip != "" ? var.private_ip : null
}
