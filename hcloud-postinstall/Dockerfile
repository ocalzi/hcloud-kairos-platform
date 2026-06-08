FROM alpine:3.19

ARG HCLOUD_CLI_VERSION=1.51.0

# bash for `set -euo pipefail`, jq for filtering hcloud's JSON output, curl
# to pull the CLI binary at build time.
RUN apk add --no-cache curl jq bash && \
    curl -sSL "https://github.com/hetznercloud/cli/releases/download/v${HCLOUD_CLI_VERSION}/hcloud-linux-amd64.tar.gz" \
    | tar xz -C /usr/local/bin hcloud

COPY post-install.sh /usr/local/bin/post-install.sh
RUN chmod +x /usr/local/bin/post-install.sh

ENTRYPOINT ["/usr/local/bin/post-install.sh"]
