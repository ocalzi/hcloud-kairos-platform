variable "hcloud_token" {
  description = "Hetzner Cloud API token. Generate one per project in the Hetzner console."
  type        = string
  sensitive   = true
}

variable "hetzner_location" {
  description = "Hetzner location for all servers in this project (e.g. fsn1, nbg1, hel1). Any LoadBalancer that HCCM later provisions should land in the same location to keep latency to the backend nodes low."
  type        = string
  default     = "fsn1"
}

variable "hetzner_network_zone" {
  description = "Hetzner network zone matching the location (e.g. eu-central for fsn1/nbg1/hel1)."
  type        = string
  default     = "eu-central"
}

variable "ssh_public_key" {
  description = "OpenSSH public key injected into the rescue console (ssh-ed25519 ... your-laptop)."
  type        = string
}

variable "node_type" {
  description = "Hetzner server type for the gateway / worker nodes. cx23 = 2 vCPU / 4 GB (smallest viable for k3s); cpx32 = 4 vCPU / 8 GB."
  type        = string
  default     = "cx23"
}

variable "kairos_image_id" {
  description = "ID of the custom Kairos ISO uploaded to the Hetzner project (`hcloud iso list`)."
  type        = string
}

variable "network_cidr" {
  description = "Top-level CIDR of the private network. Subnets carve this up further."
  type        = string
  default     = "10.0.0.0/8"
}

variable "kairos_user_password" {
  description = "Password for the `kairos` user injected via cloud-init. Plaintext is accepted by Hadron; use `openssl passwd -6` for SHA-512 crypt in real deployments."
  type        = string
  sensitive   = true
}

variable "le_email" {
  description = "Email address used to register the Let's Encrypt ACME account. Receives expiry warnings."
  type        = string
}

variable "netbird_domain" {
  description = "Public FQDN the Netbird dashboard / management is served from (e.g. showcase.calzi.eu). Must point at the gateway public IP — handled by ovh-mgmt."
  type        = string
}

variable "netbird_encryption_key" {
  description = "32-byte base64 secret used by Netbird server to encrypt state at rest. Generate with: openssl rand -base64 32"
  type        = string
  sensitive   = true
}

variable "admin_cidrs" {
  description = "CIDRs allowed to reach SSH (22) and the k3s API (6443) on the gateway. Discover your current public IPv4 with `curl -4 ifconfig.me`."
  type        = list(string)
  validation {
    condition     = length(var.admin_cidrs) > 0
    error_message = "admin_cidrs must contain at least one CIDR — leaving SSH/k3s API world-open is not allowed."
  }
}
