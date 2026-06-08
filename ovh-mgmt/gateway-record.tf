# A record: <subdomain>.<zone> -> gateway public IPv4.
#
# OVH does NOT auto-publish records on the live nameservers — the apex zone
# gets a refresh signal on a periodic cycle (up to a few hours). For a
# showcase that's tolerable; for impatient demos run a manual refresh from
# the OVH UI (Domain -> zone -> "Refresh the zone").
#
# Note: the OVH Terraform provider does not expose a refresh action. The
# clean workaround in production is a `null_resource` + `local-exec` calling
# `POST /domain/zone/{zone}/refresh` via `ovhapi` / `curl`. Kept out of this
# showcase to keep the dependency surface to OpenTofu + provider only.
resource "ovh_domain_zone_record" "gateway" {
  zone      = var.zone
  subdomain = var.subdomain
  fieldtype = "A"
  ttl       = var.ttl
  target    = var.gateway_ipv4
}
