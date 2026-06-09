# Public-facing firewall on the gateway.
#
# 80/443 open to the world — Traefik terminates HTTPS for Netbird and
# cert-manager solves the ACME HTTP-01 challenge over the same :80.
#
# 22 (SSH) and 6443 (k3s API) restricted to var.admin_cidrs. A leaked
# kubeconfig or password cannot then be exercised from a random IP.
#
# The attachment is a separate resource so adding/removing servers from
# the firewall doesn't force a recreate of the rule set.
resource "hcloud_firewall" "gateway" {
  name = "gateway-showcase"

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "HTTP — Traefik + ACME HTTP-01"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "HTTPS — Traefik"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.admin_cidrs
    description = "SSH — admin only"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = var.admin_cidrs
    description = "k3s API — admin only"
  }
}

resource "hcloud_firewall_attachment" "gateway" {
  firewall_id = hcloud_firewall.gateway.id
  server_ids  = [module.gateway.id]
}
