# ovh-mgmt

OpenTofu project that publishes the **public DNS entry** for the platform.

This is intentionally a separate project from `hcloud-mgmt` — the DNS layer
and the compute layer live on different OVH/Hetzner credentials, fail
independently, and typically rotate at very different cadences.

## What it provisions

| Resource                    | Purpose                                                            |
|-----------------------------|--------------------------------------------------------------------|
| `ovh_domain_zone_record`    | A record `<subdomain>.<zone>` → gateway public IPv4.               |

## Prerequisites

- **OpenTofu ≥ 1.6**
- OVH account with API credentials. Generate the trio at
  https://eu.api.ovh.com/createToken/.

  Minimum required permissions on the consumer key:
  `GET/POST/PUT/DELETE /domain/zone/<your-zone>/*`

  The provider accepts credentials from **either**:

  - Terraform variables in your gitignored `terraform.tfvars` —
    convenient for local applies, keeps everything in one place:

    ```hcl
    ovh_application_key    = "..."
    ovh_application_secret = "..."
    ovh_consumer_key       = "..."
    ```

  - Environment variables — preferred in CI:

    ```sh
    export OVH_ENDPOINT=ovh-eu
    export OVH_APPLICATION_KEY=...
    export OVH_APPLICATION_SECRET=...
    export OVH_CONSUMER_KEY=...
    ```

  TF variables win when both are set.

- A DNS zone already managed by OVH (apex domain like `calzi.eu`).
- The gateway's public IPv4 — output of `hcloud-mgmt` after `tofu apply`:

  ```sh
  cd ../hcloud-mgmt && tofu output -raw gateway_public_ip
  ```

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — fill in zone, subdomain, gateway_ipv4

tofu init
tofu plan
tofu apply
```

After apply, the record exists in the OVH zone but may take a few hours to
propagate — the OVH Terraform provider does not expose a zone-refresh
action, so the apex zone serves the new value on its next periodic refresh
cycle. For impatient demos, trigger a manual refresh from the OVH UI
(Domain → zone → "Refresh the zone"), then:

```sh
dig +short showcase.calzi.eu
```

## Why a separate project?

- **Blast radius.** A botched DNS plan should not be able to ruin a working
  cluster, and vice versa. Splitting projects means `tofu destroy` in one
  doesn't touch the other.
- **Provider isolation.** The OVH provider needs four secrets unrelated to
  Hetzner. Keeping them out of the compute state is cleaner.
- **Two-step bootstrap is honest.** The gateway IP only exists after
  `hcloud-mgmt apply`. A merged config would force a multi-pass apply
  with a `terraform_remote_state` data source — more moving parts for the
  same outcome.

## File layout

| Path                          | Role                                              |
|-------------------------------|---------------------------------------------------|
| `versions.tf`                 | Provider + OpenTofu version pins.                 |
| `main.tf`                     | OVH provider config (endpoint + credentials from variables). |
| `variables.tf`                | Input variables.                                  |
| `gateway-record.tf`           | The A record.                                     |
| `outputs.tf`                  | FQDN + resolved target for downstream consumers.  |
