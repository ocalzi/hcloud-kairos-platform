# OVH provider — credentials can come from either:
#   1. Terraform variables below (handy for local apply, write into a
#      gitignored terraform.tfvars).
#   2. Environment variables (OVH_ENDPOINT, OVH_APPLICATION_KEY,
#      OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY) — TF variables win when set.
# Generate at https://eu.api.ovh.com/createToken/
provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
