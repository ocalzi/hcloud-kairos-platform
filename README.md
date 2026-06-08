# hcloud-kairos-platform

Smallest possible production-grade Kubernetes on Hetzner Cloud — minimal cost,
fully integrated with Hetzner primitives.

Stack: **Kairos** + **k3s** + **HCCM** + **Cilium** + **cert-manager** + **Gateway API**.

Author: **Olivier Calzi** — Golden Kubestronaut
([github.com/ocalzi](https://github.com/ocalzi))

This is a public showcase tied to a LinkedIn series and accompanying blog
posts. It is **not** a one-click installer — it is a reference implementation
you can read end-to-end in an evening and adapt.

## What's in this repo

```
hcloud-kairos-platform/
├── hcloud-mgmt/         # OpenTofu: network, gateway, LBs, workers
└── hcloud-postinstall/  # Helper image: detach the Kairos installer ISO
                         # and power VMs back on after first install.
```

Two components, both small. Each ships with its own README explaining what it
does and how to run it.

## Background

- Blog series: https://portefolio.calzi.eu/blog/hetzner-hccm-kairos
- Upstream Hadron PR adding Hetzner cloud-provider hooks: https://github.com/kairos-io/hadron/pull/379
- This is my first OpenTofu project after several years on Terraform — the
  layout, comments, and module split reflect that bias.

## Why this exists

Most "k8s on a single cloud" tutorials either:
- pull in a managed control plane (defeats the cost angle), or
- skip the cloud-provider integration (no LoadBalancer Services, no volume
  provisioning, no node IP coherence).

This repo wires Kairos + k3s into Hetzner the way a managed cluster would
expect: HCCM for node/loadbalancer reconciliation, the Hetzner CSI driver for
PVs, Cilium for the dataplane, and Gateway API on top for ingress. The result
is a cluster that costs a coffee a day and behaves like the bigger ones.

## License

MIT.
