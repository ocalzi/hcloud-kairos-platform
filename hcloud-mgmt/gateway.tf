# Gateway node — first node to come up. Owns:
#   - Default outbound route for the private network (NAT MASQUERADE)
#   - HTTPS termination via cert-manager + Traefik / Gateway API
#   - Public k3s API endpoint (firewalled to var.management_ips in a real deploy)
#
# Renders the Kairos cloud-init from a templatefile call. Real configs include
# k3s flags, traefik HelmChartConfig, and cert-manager bootstrap manifests;
# this showcase stubs them out so the file stays readable.
locals {
  gateway_hostname = "gateway-showcase"
  gateway_user_data = templatefile("${path.module}/templates/gateway-cloud-init.yaml.tpl", {
    hostname            = local.gateway_hostname
    ssh_authorized_keys = jsonencode([var.ssh_public_key])
    template_password   = var.kairos_user_password
    private_cidr        = var.network_cidr
    le_email            = var.le_email
    netbird_domain      = var.netbird_domain
    encryption_key      = var.netbird_encryption_key
  })
}

module "gateway" {
  source = "./modules/hetzner-server"

  name        = local.gateway_hostname
  server_type = var.node_type
  location    = var.hetzner_location
  network_id  = module.network.network_id
  subnet_id   = module.network.subnet_ids["management"]
  iso_id      = var.kairos_image_id
  ssh_key_id  = hcloud_ssh_key.this.id
  user_data   = local.gateway_user_data
  private_ip  = "10.0.3.2"
}

# After `tofu apply`:
#   1. The VM boots the Kairos ISO, installs to disk, powers off.
#   2. Run hcloud-postinstall (one-shot job in CI) — it detaches the ISO and
#      powers the VM back on. See hcloud-postinstall/README.md.
#   3. The VM boots from disk, applies the Kairos config, joins as a k3s
#      single-node control plane, and starts serving.
