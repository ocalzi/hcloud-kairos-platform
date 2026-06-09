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
├── hcloud-mgmt/         # OpenTofu: network, gateway, workers
├── ovh-mgmt/            # OpenTofu: public DNS record for the gateway
└── hcloud-postinstall/  # Helper image: detach the Kairos installer ISO
                         # and power VMs back on after first install.
```

Three components, all small. Each ships with its own README explaining what
it does and how to run it. Bootstrap order is `hcloud-mgmt` →
`hcloud-postinstall` → `ovh-mgmt` (the DNS record consumes the gateway IP
that `hcloud-mgmt` produces).

## Architecture at a glance

```mermaid
flowchart TB
  User([User])

  subgraph Hetzner["Hetzner Cloud project"]
    direction TB

    subgraph Net["hcloud_network 10.0.0.0/8"]
      direction TB
      Gateway["Gateway VM<br/>Kairos + k3s server<br/>10.0.3.2 (management)"]
      Workers["Worker VMs<br/>Kairos + k3s agent<br/>(backend / frontend subnets)"]
      AppLB["HCCM-managed LB<br/>Service type=LoadBalancer<br/>HCLOUD_LOAD_BALANCERS_USE_PRIVATE_IP=true"]
    end

    ISO[("Kairos ISO<br/>custom, uploaded")]
  end

  User -->|HTTPS| AppLB
  AppLB -->|private IP :NodePort| Gateway
  AppLB -->|private IP :NodePort| Workers
  ISO -.first boot.-> Gateway
  ISO -.first boot.-> Workers
```

The LoadBalancer is provisioned by the **Hetzner Cloud Controller Manager**
(HCCM) at runtime from a `Service type=LoadBalancer` — not by OpenTofu.
That is why this repo has no `hcloud_load_balancer` resource: the cluster
owns its own LBs once HCCM is up.

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

## AI-assisted authorship

Per [Linux Foundation generative-AI guidance](https://www.linuxfoundation.org/legal/generative-ai)
and the spirit of [Model Card](https://modelcards.withgoogle.com/about) /
disclosure best practice:

- Significant portions of the OpenTofu HCL, shell script, CI workflows, and
  prose in this repository were drafted with the assistance of
  **Anthropic Claude (Opus 4.7)** via [Claude Code](https://claude.com/claude-code).
- Every file has been read, reviewed, edited, and accepted by a human
  (Olivier Calzi). The author retains responsibility for correctness,
  security, and licensing compliance under the MIT terms below.
- No third-party copyrighted code was knowingly ingested into the prompt
  context. All design choices — module split, two-phase boot model,
  `hcloud_image` data-source lookup, `ignore_changes` policy — were
  human-directed; the AI produced the boilerplate to express them.
- AI-assisted commits in this repository are signed off with a
  `Co-Authored-By: Claude` trailer per the Linux DCO convention extension
  for AI co-authorship, so blame/`git log` makes the provenance auditable.

If you reuse or fork this code, the same review discipline is recommended.

## License

[MIT](LICENSE).
