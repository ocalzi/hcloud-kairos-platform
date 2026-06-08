# hcloud-mgmt

OpenTofu project that lays down the **shared infrastructure** for the Kairos
platform: private network, subnets, SSH key, gateway node, and the modules
used to spin up workers and load balancers.

## What it provisions

| Resource              | Purpose                                                                    |
|-----------------------|----------------------------------------------------------------------------|
| `hcloud_network`      | Top-level `/8` private network (`net01`).                                  |
| `hcloud_network_subnet` x3 | `backend` / `frontend` / `management` `/24`s.                          |
| `hcloud_ssh_key`      | Rescue-console fallback key.                                               |
| `module.gateway`      | Single Kairos VM in `management` — NAT, k3s control plane, ingress edge.   |

The modules in `modules/` are designed to be re-used for additional
nodes/LBs in sibling projects.

## Two-phase bootstrap

Hetzner has no concept of "boot from ISO then disk." Kairos works around it
by powering the VM off after install:

```
tofu apply
  └── Hetzner creates VM
        ├── Disk image (debian-13) installed   (throwaway — gets wiped)
        ├── Kairos ISO attached as CD-ROM
        └── First boot: ISO -> Kairos installer
              └── Writes Kairos to disk -> powers off

hcloud-postinstall (CI job)
  └── hcloud server detach-iso <id>
  └── hcloud server poweron   <id>
        └── VM boots from disk -> Kairos / k3s up
```

Without the second step the VM stays off — the installer powered it off on
purpose, and the ISO is still mounted so a manual reboot would re-run the
installer.

See [`../hcloud-postinstall/`](../hcloud-postinstall/) for the helper image.

## Prerequisites

- **OpenTofu ≥ 1.6** (`tofu version`)
- Hetzner Cloud project + API token
- Custom Kairos ISO uploaded to the same project (`hcloud iso list`)
- An SSH keypair to load into the rescue console

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — fill in token, SSH key, ISO id

tofu init
tofu plan
tofu apply
```

After `apply` finishes, run `hcloud-postinstall` against the same Hetzner
project to bring the gateway online.

## File layout

| Path                              | Role                                                       |
|-----------------------------------|------------------------------------------------------------|
| `versions.tf`                     | Provider + OpenTofu version pins.                          |
| `main.tf`                         | Provider config + shared SSH key.                          |
| `variables.tf`                    | Input variables.                                           |
| `outputs.tf`                      | Public/private IPs + network ID for downstream projects.   |
| `network.tf`                      | The `module.network` call (subnet split lives here).       |
| `gateway.tf`                      | Gateway node + Kairos cloud-init template render.          |
| `servers.tf`                      | Placeholder for worker nodes — documented two-phase boot.  |
| `templates/gateway-cloud-init.*`  | Kairos cloud-init for the gateway.                         |
| `modules/hetzner-network/`        | `hcloud_network` + per-subnet `hcloud_network_subnet`.     |
| `modules/hetzner-server/`         | `hcloud_server` with ISO boot + private network attach.    |
| `modules/hetzner-lb/`             | `hcloud_load_balancer` + private network attach.           |

## Why OpenTofu, not Terraform

This is my first OpenTofu project after several years of Terraform — the
license shift made the call easy, and at this size the syntax is identical.
The CLI is `tofu` everywhere in the comments and CI.
