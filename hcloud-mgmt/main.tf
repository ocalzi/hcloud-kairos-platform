provider "hcloud" {
  token = var.hcloud_token
}

# Shared SSH key — handed to every server as a console/rescue fallback.
# Day-to-day access goes through the cluster (kubectl) rather than SSH.
resource "hcloud_ssh_key" "this" {
  name       = "hcloud-kairos-platform"
  public_key = var.ssh_public_key
}
