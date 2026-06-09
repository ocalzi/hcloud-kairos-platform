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

Three CI files ship in this directory — pick the one your forge uses:

| File                                | Use it on        | Pushes to                                |
|-------------------------------------|------------------|------------------------------------------|
| `.gitlab-ci.yml`                    | GitLab CI        | `$CI_REGISTRY_IMAGE` (project registry)  |
| `.github/workflows/build.yml`       | GitHub Actions   | `ghcr.io/ocalzi/hcloud-postinstall`      |
| `.gitea/workflows/build.yml`        | Gitea Actions    | `quay.io/ocalzi/hcloud-postinstall`      |

Every pipeline runs `shellcheck` on `post-install.sh` first, then builds and
pushes the image. The script is held to zero shellcheck warnings.

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
