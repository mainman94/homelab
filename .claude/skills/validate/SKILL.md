---
name: validate
description: Validate every Terraform stack and run the tftest suites before committing. Use before opening a PR in this repo, or when asked to check the infrastructure config still holds.
---

# validate

Run the repo's own gate and report failures concisely. Nothing here needs credentials.

## Steps

1. `make check` — pre-commit hooks, `terraform validate` per stack, and the tftest suites.
2. Summarize: what passed, what failed, and the exact `file:line` of each failure.
3. If `terraform_fmt` reports changes, apply them (`make fmt`) and say so.
4. Do not commit if anything fails unless the user explicitly accepts.

## What it covers, and what it cannot

- **`validate`** runs with `-backend=false` against all seven stacks — no state, no
  credentials. It proves the config parses and references resolve, not that a plan is safe.
- **`test`** runs `terraform test` for the stacks with a `tests/` directory. Today that is
  `talos` only: the `github` stack configures its provider from an `ephemeral` OpenBao
  read, and Terraform's test mocking rejects ephemeral resources during setup.
- **Neither sees the real plan.** A change that validates cleanly can still destroy
  something on apply — read the TFC plan before merging anything that touches a resource's
  identity.

## Terraform, not OpenTofu

Four stacks use `ephemeral` blocks, a Terraform >= 1.10 feature OpenTofu does not
implement. `mise.toml` pins the version; `tofu validate` fails on those four.
