# Cloudflare Root Stack

This stack manages the `hauptmann.dev` Cloudflare zone through the shared Cloudflare module from `mainman94/homelab-terraform-modules`.

## What it manages

The current configuration manages:

- A records for `hauptmann.dev` and `*.hauptmann.dev`
- tunnel-backed CNAME records for backend services such as `registry`
- an SPF record
- a DKIM record
- an email routing rule for the `hello@hauptmann.dev` local part

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

- `public_ip`
- `a_records_hauptmann_dev`
- `cname_backend_records`

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
