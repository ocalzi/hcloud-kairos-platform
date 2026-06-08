variable "hcloud_token" {
  description = "Hetzner Cloud API token. Generate one per project in the Hetzner console."
  type        = string
  sensitive   = true
}

variable "hetzner_location" {
  description = "Hetzner location for all servers and load balancers (e.g. fsn1, nbg1, hel1)."
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
  description = "Hetzner server type for the gateway / worker nodes. cpx32 = 4 vCPU / 8 GB; cx23 = 2 vCPU / 4 GB."
  type        = string
  default     = "cpx32"
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
