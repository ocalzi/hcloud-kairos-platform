#!/usr/bin/env bash
#
# hcloud-postinstall — detach the Kairos installer ISO from VMs that finished
# their first-boot install (status=off + ISO still attached) and power them
# back on.
#
# Required env:
#   HCLOUD_TOKEN  Hetzner Cloud API token (project-scoped, read/write).
#
# Optional env:
#   DRY_RUN=true  Print intended actions, change nothing.
#
# Exit codes:
#   0  All matching VMs handled (or none found).
#   1  At least one detach/poweron failed.
#   2  Bad invocation / missing prerequisites.

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: post-install.sh

Required env:
  HCLOUD_TOKEN   Hetzner Cloud API token.

Optional env:
  DRY_RUN=true   Print actions instead of executing them.

Behaviour:
  Lists all servers in the project, picks those with status=off whose
  attached ISO name contains "kairos" (case-insensitive). For each match
  it runs `hcloud server detach-iso <id>` followed by
  `hcloud server poweron <id>`.

  Idempotent: if no VMs match, exits 0 without doing anything.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

log() { printf '[%s] %s\n' "$1" "$2"; }

if [[ -z "${HCLOUD_TOKEN:-}" ]]; then
    log ERROR "HCLOUD_TOKEN is not set."
    usage
    exit 2
fi

export HCLOUD_TOKEN

DRY_RUN="${DRY_RUN:-false}"

# `hcloud server list -o json` returns every server in the project. We filter
# to off + ISO-attached-and-named-like-kairos inside jq so the resulting array
# only contains the work we actually want to do.
mapfile -t targets < <(
    hcloud server list -o json |
        jq -r '.[]
               | select(.status == "off")
               | select(.iso != null)
               # Public ISOs expose the filename in .iso.name; private uploads
               # leave .name empty and stash the filename in .description.
               # Match either so a custom Kairos ISO upload works the same.
               | select(((.iso.name // "") + " " + (.iso.description // "")) | ascii_downcase | contains("kairos"))
               | "\(.id)\t\(.name)\t\(.iso.description // .iso.name)"'
)

if [[ ${#targets[@]} -eq 0 ]]; then
    log INFO "No Kairos VMs in 'off' state with an ISO attached. Nothing to do."
    exit 0
fi

failures=0
for row in "${targets[@]}"; do
    IFS=$'\t' read -r id name iso_name <<<"$row"
    log INFO "Found Kairos server off with ISO attached: ${name} (id=${id}, iso=${iso_name})"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log DRY-RUN "Would detach ISO and power on ${name} (id=${id})"
        continue
    fi

    if ! hcloud server detach-iso "${id}"; then
        log ERROR "detach-iso failed for ${name} (id=${id})"
        failures=$((failures + 1))
        continue
    fi

    if ! hcloud server poweron "${id}"; then
        log ERROR "poweron failed for ${name} (id=${id})"
        failures=$((failures + 1))
        continue
    fi

    log INFO "Recovered ${name} (id=${id})"
done

if [[ ${failures} -gt 0 ]]; then
    log ERROR "${failures} server(s) failed. See errors above."
    exit 1
fi

log INFO "Done. ${#targets[@]} server(s) processed."
