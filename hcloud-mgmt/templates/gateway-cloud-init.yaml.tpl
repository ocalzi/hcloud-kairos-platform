#cloud-config

install:
  auto: true
  device: /dev/sda
  poweroff: true

hostname: ${hostname}

users:
  - name: kairos
    passwd: ${template_password}
    groups:
      - admin
    ssh_authorized_keys: ${ssh_authorized_keys}

# Default k3s — traefik + flannel + kube-proxy stay enabled (light footprint, single-purpose box).
# servicelb disabled because Netbird is fronted by an external Hetzner LB.
k3s:
  enabled: true
  args:
    - --cluster-init
    - --disable=servicelb
    - --write-kubeconfig-mode=644

stages:
  boot:
    - name: "enable ip forwarding"
      commands:
        - mkdir -p /etc/sysctl.d
        - echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-nat.conf
        - sysctl -w net.ipv4.ip_forward=1 || echo 1 > /proc/sys/net/ipv4/ip_forward
    - name: "nat masquerade for private network"
      commands:
        # -I inserts at top of chain so k3s/flannel reloads don't bury our rule
        - |
          iptables -t nat -C POSTROUTING -s ${private_cidr} ! -d ${private_cidr} -j MASQUERADE 2>/dev/null || \
            iptables -t nat -I POSTROUTING -s ${private_cidr} ! -d ${private_cidr} -j MASQUERADE
        - |
          iptables -C FORWARD -s ${private_cidr} -j ACCEPT 2>/dev/null || \
            iptables -I FORWARD -s ${private_cidr} -j ACCEPT
        - |
          iptables -C FORWARD -d ${private_cidr} -j ACCEPT 2>/dev/null || \
            iptables -I FORWARD -d ${private_cidr} -j ACCEPT

write_files:
  # Traefik: bind directly to host:80/443 via hostPort.
  # External Hetzner LB forwards 80/443 → gateway host:80/443 → traefik.
  # No klipper-lb (servicelb disabled to avoid double-LB).
  - path: /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
    permissions: "0600"
    owner: "root"
    content: |
      apiVersion: helm.cattle.io/v1
      kind: HelmChartConfig
      metadata:
        name: traefik
        namespace: kube-system
      spec:
        valuesContent: |-
          service:
            enabled: false
          ports:
            web:
              port: 8000
              hostPort: 80
            websecure:
              port: 8443
              hostPort: 443
          deployment:
            kind: DaemonSet

  # cert-manager (Let's Encrypt HTTP-01)
  - path: /var/lib/rancher/k3s/server/manifests/cert-manager.yaml
    permissions: "0600"
    owner: "root"
    content: |
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: cert-manager
        namespace: kube-system
      spec:
        chart: cert-manager
        repo: https://charts.jetstack.io
        version: v1.16.2
        targetNamespace: cert-manager
        createNamespace: true
        bootstrap: true
        valuesContent: |-
          crds:
            enabled: true
          replicaCount: 1
          webhook:
            replicaCount: 1
          cainjector:
            replicaCount: 1

  # ClusterIssuer for Let's Encrypt
  - path: /var/lib/rancher/k3s/server/manifests/letsencrypt-issuer.yaml
    permissions: "0600"
    owner: "root"
    content: |
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          server: https://acme-v02.api.letsencrypt.org/directory
          email: ${le_email}
          privateKeySecretRef:
            name: letsencrypt-prod-account-key
          solvers:
            - http01:
                ingress:
                  class: traefik

  # Netbird OCI Helm chart (cclloyd/helm-netbird) — minimal config, traefik ingress
  - path: /var/lib/rancher/k3s/server/manifests/netbird.yaml
    permissions: "0600"
    owner: "root"
    content: |
      apiVersion: v1
      kind: Namespace
      metadata:
        name: netbird
      ---
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: netbird
        namespace: kube-system
      spec:
        chart: oci://ghcr.io/cclloyd/helm-netbird/netbird
        version: 0.0.0-latest
        targetNamespace: netbird
        bootstrap: true
        valuesContent: |-
          global:
            domain:
              global: ${netbird_domain}
              vpn: netbird.local
            server:
              encryption_key: "${encryption_key}"
          # Upstream chart is stale (appVersion pinned to 0.66.0); pin newer
          # netbird/dashboard tags ourselves until the chart catches up.
          dashboard:
            image:
              tag: v2.39.0
          server:
            image:
              tag: 0.72.2
          route:
            enabled: false
          ingress:
            enabled: false
      ---
      # h2c-annotated Service so Traefik speaks HTTP/2 cleartext to netbird-server
      # for gRPC streams (management + signal). Without h2c, Traefik downgrades
      # to HTTP/1.1 and gRPC silently breaks (CLI hangs with no server-side log).
      apiVersion: v1
      kind: Service
      metadata:
        name: netbird-server-h2c
        namespace: netbird
        annotations:
          traefik.ingress.kubernetes.io/service.serversscheme: h2c
      spec:
        selector:
          netbird-app: netbird-server
        ports:
          - {name: h2c, port: 80, targetPort: 80, protocol: TCP}
      ---
      # Ingress lives in the same file as the namespace so it applies in lockstep
      # (separate files can race when k3s applies manifests in alphabetical order).
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: netbird
        namespace: netbird
        annotations:
          cert-manager.io/cluster-issuer: letsencrypt-prod
          traefik.ingress.kubernetes.io/router.entrypoints: websecure
          traefik.ingress.kubernetes.io/router.tls: "true"
      spec:
        ingressClassName: traefik
        tls:
          - secretName: netbird-tls
            hosts:
              - ${netbird_domain}
        rules:
          - host: ${netbird_domain}
            http:
              paths:
                - path: /api
                  pathType: Prefix
                  backend:
                    service:
                      name: netbird-server
                      port:
                        number: 80
                # gRPC paths — MUST go to the h2c Service for HTTP/2 backend
                - path: /management.ManagementService
                  pathType: Prefix
                  backend:
                    service:
                      name: netbird-server-h2c
                      port:
                        number: 80
                - path: /signalexchange.SignalExchange
                  pathType: Prefix
                  backend:
                    service:
                      name: netbird-server-h2c
                      port:
                        number: 80
                # Relay WebSocket (introduced in netbird-server v0.71+)
                - path: /relay
                  pathType: Prefix
                  backend:
                    service:
                      name: netbird-server
                      port:
                        number: 80
                # Embedded Dex IdP — served on the netbird-server pod at /oauth2*
                - path: /oauth2
                  pathType: Prefix
                  backend:
                    service:
                      name: netbird-server
                      port:
                        number: 80
                # Dashboard OAuth callback paths (Dex redirects users back here)
                - path: /nb-auth
                  pathType: Prefix
                  backend:
                    service:
                      name: netbird-dashboard
                      port:
                        number: 80
                - path: /nb-silent-auth
                  pathType: Prefix
                  backend:
                    service:
                      name: netbird-dashboard
                      port:
                        number: 80
                - path: /
                  pathType: Prefix
                  backend:
                    service:
                      name: netbird-dashboard
                      port:
                        number: 80
