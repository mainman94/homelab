# Cloudflare Root Stack

This stack manages the `hauptmann.dev` Cloudflare zone through the shared Cloudflare module from `mainman94/homelab-terraform-modules`.

## What it manages

The current configuration manages:

- A records for `hauptmann.dev` and `*.hauptmann.dev`
- tunnel-backed CNAME records for backend services such as `registry`
- an SPF record
- a DKIM record
- an email routing rule for the `hello@hauptmann.dev` local part
- a custom WAF ruleset (`http_request_firewall_custom`) with a GeoBlock rule

## Module versioning

This stack intentionally consumes a tagged module release rather than tracking `main`.

When the shared Cloudflare module changes:

1. Update the module in `../homelab-terraform-modules/modules/cloudflare`.
2. Validate it locally.
3. Commit and tag a new `cloudflare-x.y.z` release in the module repository.
4. Bump the `source` ref in [main.tf](main.tf).
5. Run `terraform init -upgrade` and `terraform plan` in this stack.

## Required inputs

The provider and module currently require these inputs:

- `CLOUDFLARE_API_KEY`
- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV`
- `CLOUDFLARE_TUNNEL_STRASSGANG_ID`
- `cloudflare_domain`
- `cloudflare_dkim_key`
- `MY_EMAIL`

Optional inputs with defaults include:

- `a_records_hauptmann_dev`
- `cname_backend_records`

## Vault-sourced values

Some inputs are read straight from OpenBao instead of workspace variables:

| Value | KV path | Key |
|-------|---------|-----|
| Cloudflare API token | `homelab/prod/cloudflare` | `API_KEY` (ephemeral, never in state) |
| Cloudflare Access IdP creds | `homelab/prod/pocket-id-cloudflare-access` | `CLIENT_ID` / `CLIENT_SECRET` |
| Public IP for the A records | `homelab/prod/network` | `PUBLIC_IP` |

The `cloudflare` workspace's `tfc-cloudflare` role grants read access to exactly
these paths; see [`../openbao/tfc-vault-auth.tf`](../openbao/tfc-vault-auth.tf).

## GeoBlock rule

The `cloudflare_ruleset.firewall_custom` resource in [main.tf](main.tf) manages the
zone's `http_request_firewall_custom` phase. It currently holds a single rule that
blocks requests to `*.hauptmann.dev` whose source country is not `AT`.

The rule list is managed exhaustively: a rule removed from `main.tf` is removed from
the zone on the next apply, so add new custom rules there rather than in the
Cloudflare dashboard.

## Usage

1. In Terraform Cloud, set the required Cloudflare secrets for the `cloudflare` workspace.
2. For local runs, export the same values in your shell or provide them through a local `.tfvars` file that is not committed.
3. Run `terraform init` in this directory.
4. Review changes with `terraform plan`.
5. Apply with `terraform apply` once the plan is correct.

## Terraform Cloud backend

This stack uses the remote Terraform backend in the `eggenberg-homelab` organization and the `cloudflare` workspace.

## Notes

- The current root module uses `CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV` rather than `cloudflare_zone_id`.
- DNS, tunnel, and mail-routing behavior is implemented in the shared module, so review module releases before upgrading the pinned version.
