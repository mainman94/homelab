# Infisical Root Stack

This stack currently contains a basic Terraform example for Infisical project, workspace, folder, and secret management.

## Current state

The current configuration is closer to a sandbox or proof of concept than a production-ready root stack. It creates:

- an Infisical project named `MyApp`
- a `dev` workspace
- a `/database` folder
- a generated `DB_PASSWORD` secret

## Required inputs

The provider requires:

- `infisical_client_id`
- `infisical_client_secret`

## Usage

1. In Terraform Cloud, set the required Infisical client credentials for the `secrets` workspace.
2. For local runs, export the same values in your shell or provide them through a local `.tfvars` file that is not committed.
3. Run `terraform init` in this directory.
4. Review changes with `terraform plan`.
5. Apply with `terraform apply` once the plan is correct.

## Terraform Cloud backend

This stack uses the remote Terraform backend in the `eggenberg-homelab` organization and the `secrets` workspace.

## Notes

- The resources in [main.tf](main.tf) are example-oriented and use hard-coded names.
- `random_password` is used to generate the database password and then stores that generated value in Infisical.
- If this stack becomes production-facing, the current example resources should be replaced with environment-specific inputs and naming.
