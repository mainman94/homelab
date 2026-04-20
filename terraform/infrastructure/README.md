# Infrastructure Root Stack

This stack manages shared infrastructure integrations that do not fit one of the provider-specific stacks.

## What it manages

The current configuration provisions a Backblaze B2 bucket through the shared Backblaze module from `mainman94/homelab-terraform-modules`.

At the moment, the stack manages:

- a Backblaze B2 bucket named by `bucket_name`

## Module versioning

This stack intentionally consumes a tagged module release rather than tracking `main`.

When the shared Backblaze module changes:

1. Update the module in `../homelab-terraform-modules/modules/backblaze`.
2. Validate it locally.
3. Commit and tag a new `backblaze-x.y.z` release in the module repository.
4. Bump the `source` ref in [main.tf](main.tf).
5. Run `terraform init -upgrade` and `terraform plan` in this stack.

## Required inputs

The provider requires:

- `APPLICATION_KEY`
- `APPLICATION_KEY_ID`

Optional inputs with defaults include:

- `bucket_name`

## Usage

1. In Terraform Cloud, set the required Backblaze credentials for the `backblaze` workspace.
2. For local runs, export the same values in your shell or provide them through a local `.tfvars` file that is not committed.
3. Run `terraform init` in this directory.
4. Review changes with `terraform plan`.
5. Apply with `terraform apply` once the plan is correct.

## Terraform Cloud backend

This stack uses the remote Terraform backend in the `eggenberg-homelab` organization and the `backblaze` workspace.

## Notes

- Backblaze resource behavior is implemented in the shared module, so review module releases before upgrading the pinned version.
