variable "name" {
  description = "Server name. MUST match the hostname Kairos sets via cloud-init — HCCM matches Node objects to Hetzner servers by name."
  type        = string
}

variable "server_type" {
  description = "Hetzner server type (e.g. cpx32, cx23, cax21). ARM types start with cax*, everything else is x86."
  type        = string
}

variable "location" {
  description = "Hetzner location slug (fsn1, nbg1, hel1, ash, sin)."
  type        = string
}

variable "network_id" {
  description = "ID of the parent hcloud_network the server attaches to."
  type        = string
}

variable "subnet_id" {
  description = "ID of the hcloud_network_subnet the server lives in. The provider needs the subnet (not just the network) to pin the server's private IP into the right /24."
  type        = string
}

variable "iso_id" {
  description = "ID of the custom Kairos ISO uploaded to Hetzner. The VM boots from this ISO once, Kairos auto-installs to disk, then powers off. hcloud-postinstall detaches the ISO and powers the VM back on."
  type        = string
}

variable "ssh_key_id" {
  description = "Hetzner SSH key ID to inject into the rescue console — useful if the install ever drops to recovery."
  type        = string
}

variable "user_data" {
  description = "Rendered Kairos / cloud-init YAML. Passed to hcloud_server.user_data."
  type        = string
  sensitive   = true
}

variable "private_ip" {
  description = "Optional static private IP. Empty -> Hetzner picks the next free address in the subnet."
  type        = string
  default     = ""
}
