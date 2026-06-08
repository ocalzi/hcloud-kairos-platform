#cloud-config
#
# Kairos / Hadron cloud-init for the gateway node.
# Stubbed for the showcase — a real config wires in:
#   - k3s server flags (--cluster-init, --disable=servicelb, ...)
#   - traefik HelmChartConfig with hostPort 80/443
#   - cert-manager + a ClusterIssuer for Let's Encrypt
#   - iptables MASQUERADE on POSTROUTING for the private CIDR
#
# Kept short here so the structure is readable in a single screen.

install:
  auto: true
  device: /dev/sda
  poweroff: true   # required for the two-phase boot — see gateway.tf

hostname: ${hostname}

users:
  - name: kairos
    # In production use a SHA-512 crypt hash (openssl passwd -6 'pw'); the
    # plaintext form is fine on the Hadron family targeted here.
    passwd: kairos
    groups:
      - admin
    ssh_authorized_keys: ${ssh_authorized_keys}

k3s:
  enabled: true
  args:
    - --cluster-init
    - --disable=servicelb
    - --write-kubeconfig-mode=644
