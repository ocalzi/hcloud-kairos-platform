# hcloud-postinstall

Tiny Alpine image that fixes one specific Kairos-on-Hetzner gotcha:

> After Kairos finishes its auto-install, it powers the VM **off**.
> Hetzner leaves the installer ISO attached. Without intervention the VM
> stays off forever, and a manual reboot just re-runs the installer.

This image:

1. Lists every server in the Hetzner project (`hcloud server list -o json`).
2. Filters to those with `status=off` **and** an attached ISO whose name
   contains `kairos` (case-insensitive).
3. For each match: `hcloud server detach-iso <id>` then
   `hcloud server poweron <id>`.
4. Reports per-server success/failure and exits non-zero on any failure.

Idempotent. Safe to run on a cron. Doesn't touch running VMs.

## Run it

The container runs as **UID 10001 (non-root)** out of the box — no
`--user` override needed, and it satisfies Kubernetes' `restricted`
PodSecurity profile without any extra `securityContext` plumbing.

```sh
docker run --rm \
  -e HCLOUD_TOKEN="$HCLOUD_TOKEN" \
  ghcr.io/ocalzi/hcloud-postinstall:latest
```

Dry-run first (recommended) to see what it would touch:

```sh
docker run --rm \
  -e HCLOUD_TOKEN="$HCLOUD_TOKEN" \
  -e DRY_RUN=true \
  ghcr.io/ocalzi/hcloud-postinstall:latest
```

## CI

CI lives at the **repo root** (one config per forge), not in this
subdirectory, because every supported forge only auto-discovers pipelines
from its own conventional root path (`.github/workflows/`,
`.gitea/workflows/`, `/.gitlab-ci.yml`):

| Config                                      | Forge            | Pushes to                                |
|---------------------------------------------|------------------|------------------------------------------|
| `/.gitlab-ci.yml`                           | GitLab CI        | `$CI_REGISTRY_IMAGE/hcloud-postinstall`  |
| `/.github/workflows/postinstall-build.yml`  | GitHub Actions   | `ghcr.io/ocalzi/hcloud-postinstall`      |
| `/.gitea/workflows/postinstall-build.yml`   | Gitea Actions    | `quay.io/ocalzi/hcloud-postinstall`      |

Every pipeline runs `shellcheck` on `post-install.sh` first, then builds and
pushes the image. The script is held to zero shellcheck warnings.

All three pipelines build with **buildah** rather than `docker build`:

- No Docker daemon, no `docker:dind`, no `docker/build-push-action`.
- Image format is forced to OCI (`--oci` / `BUILDAH_FORMAT=oci`).
- GitLab uses `quay.io/buildah/stable` directly. GitHub and Gitea use
  `redhat-actions/buildah-build` + `redhat-actions/push-to-registry` with
  `redhat-actions/podman-login` for registry auth.

The result is a fully vendor-neutral image-build chain: the only Docker Inc
software in the loop is the upstream BuildKit code that buildah itself
optionally calls — and none of it runs as a privileged daemon.

## Build it locally

The image is described by a `Containerfile` (the OCI-spec name for what
Docker historically called `Dockerfile`). Any OCI-compatible builder works:

```sh
# Podman / Buildah
podman build -t hcloud-postinstall -f Containerfile .

# Docker (auto-detects Containerfile in current dir, or pass -f)
docker build -t hcloud-postinstall -f Containerfile .
```

The `Containerfile` name is used on purpose to keep the build vendor-neutral.

## Why a container, not a one-shot script

This same job needs to run from three different forges (Gitea, GitHub Actions,
GitLab CI) and from a kubectl-driven CronJob inside the very cluster it
bootstraps. Shipping it as an image means each caller just sets
`HCLOUD_TOKEN` — no Alpine/curl/jq install dance.

## Background

Part of [`hcloud-kairos-platform`](../README.md). Full blog write-up:
https://portefolio.calzi.eu/blog/hetzner-hccm-kairos
