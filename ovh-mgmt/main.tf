# OVH provider — credentials come from environment variables:
#   OVH_ENDPOINT, OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY.
# Generate them at https://eu.api.ovh.com/createToken/
provider "ovh" {
  endpoint = var.ovh_endpoint
}
