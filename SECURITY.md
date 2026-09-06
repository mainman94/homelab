# Security Policy

## What this repository is

Infrastructure as Code for a private homelab: Terraform stacks for Cloudflare,
GitHub governance, OpenBao, Backblaze, OCI and Talos, plus an Ansible playbook
that locks the router's inbound web ports to Cloudflare. State lives in
Terraform Cloud; this repository holds configuration only.

## Reporting

Report privately via GitHub's
[security advisories](https://github.com/mainman94/homelab/security/advisories/new).
Please do not open a public issue for anything exploitable.

Worth reporting: a **secret committed by mistake**, a Cloudflare or router
rule that opens more than intended, an OpenBao policy or JWT role that grants
more than its workload needs, or a GitHub ruleset change that removes a
protection.

## What is already covered

- **No credentials are committed.** The stacks that need secrets read them
  from OpenBao through an `ephemeral` block, so the value never reaches
  Terraform state, and HCP workload identity issues a short-lived token per
  run. `gitleaks` runs as a pre-commit hook and in CI; `*.tfvars` is
  git-ignored.
- **`terraform validate` runs per stack on every pull request** without
  credentials, and the `talos` stack's variable validation is covered by a
  `terraform test` suite using mock providers.
- **trivy config scanning** runs weekly and on every pull request, uploading
  SARIF to the Security tab. `.trivyignore` carries the accepted findings,
  each with a reason.
- **Every action reference is pinned to a commit SHA**, and `zizmor` audits
  the workflows.

## Governance note

`terraform/github/` is where branch protection for every repository in this
account is defined, including the required status checks. A change there
weakens or strengthens the merge gate for all of them — treat a pull request
touching it as security-relevant even when it looks like configuration.
