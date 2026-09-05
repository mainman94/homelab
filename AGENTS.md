<!-- graft:start -->
## Graft — repo context graph

This repo is indexed in `graft/`: small linked markdown nodes that explain each
system and carry exact file:line spans, kept in sync with the code through git.

For ANY task here — understanding how something works, finding where code lives,
or scoping a change — get context from the graph before grepping or opening
source files. Re-ask freely (it's cheap) and reuse literal identifiers you
already have (symbol, error string, file name) as the query. New to this repo?
Run `graft map` first — a token-budgeted orientation (dir clusters, hubs,
hotspots), no LLM, no key.

- Run `graft ask "<your question>" --source` → ranked nodes with the relevant
  code spans inlined (each hit's ≤8-line crux by default; `--full` for whole
  definitions when the crux isn't enough). Match the tool to the task shape:
  for understanding or editing, the top node IS the answer — cite its
  `covers:` file:line spans and edit straight from `--source`. For
  exhaustive tasks ("every occurrence / every caller of this pattern"), ranked
  results are top-N, not complete — run `graft grep "<literal>"` instead
  (exhaustive over indexed files, grouped by enclosing symbol), falling back
  to raw `grep -rn` only for unindexed files.
- `graft skeleton <file>` → every definition's signature + span, ~10× cheaper
  than reading the file; use it to skim an API surface.
- `graft callers <symbol>` gives precomputed, exact edges — who calls this.
  Add `--direction out` for what it calls, or `--depth N` to walk
  transitively for the full blast radius. For structural questions, skip
  ranking and use this directly.
- Or browse: `graft/INDEX.md` lists every node; follow the links.
- Monorepos and folders of multiple repos rank fairly across sub-projects —
  hits carry `[scope/]` labels naming which one they're from. Narrow with
  `graft ask "<task>" --in <scope>/` once you know where you're working.

If a returned span is truncated ("+N more lines"), open the file at that exact
range before finalizing. Only open source files when a node genuinely lacks a
needed detail, and then at the exact file:line the node points to — never
re-read whole files.

After big code changes, refresh the graph with `graft build` (deterministic,
no API key, $0).
<!-- graft:end -->

# AGENTS

Infrastructure as Code for the homelab control plane: Terraform stacks for
Cloudflare, GitHub governance, OpenBao, Backblaze, OCI and Talos, plus an
Ansible playbook that locks the router's inbound web ports to Cloudflare.

State lives in Terraform Cloud. Shared modules live in the sibling repo
`homelab-terraform-modules`.

## Local workflow

| Command                     | What it does                                       |
| --------------------------- | -------------------------------------------------- |
| `make help`                 | List every target                                  |
| `make hooks`                | Install the git pre-commit hook (do this once)     |
| `make check`                | Everything a PR needs: hooks + validate            |
| `make validate`             | `terraform validate` every stack, no credentials   |
| `make plan STACK=cloudflare`| Plan one stack (needs credentials)                 |
| `make fmt`                  | Rewrite Terraform to canonical format              |
| `make scan`                 | The same trivy config scan CI runs                 |
| `make lint-deep`            | tflint with provider rulesets (fetches plugins)    |
| `make ansible-check`        | Dry-run the router playbook                        |

`make` uses `terraform` when it is installed and falls back to `tofu`;
override with `make TF=tofu ...`. `.devcontainer/` provides Terraform, tflint,
ansible, trivy and the hook toolchain.

**This repo needs Terraform, not OpenTofu.** `cloudflare`, `github`,
`infrastructure` and `pocket-id` fetch their credentials through an
`ephemeral "vault_kv_secret_v2"` block so the value never reaches state.
`ephemeral` is a Terraform >= 1.10 feature that OpenTofu does not implement —
`tofu validate` fails on those four with *"Blocks of type \"ephemeral\" are
not expected here"*. Those stacks pin `required_version = ">= 1.10.0"`; the
other three, which use no ephemeral blocks, stay at `>= 1.6.0` and do work
under OpenTofu.

## Automated checks

`.pre-commit-config.yaml` runs on every commit: `terraform_fmt`,
`terraform_tflint` (core ruleset, `.tflint.hcl`), `ansible-lint` on the
production profile, `yamlfmt`, `shellcheck`, `shfmt`, `gitleaks` and hygiene
hooks.

Deliberately not hooks:

- **`terraform validate`** and provider-aware tflint rules need
  `terraform init`, which pulls providers over the network on every run.
  `make validate` and `make lint-deep`.
- **`trivy`** stays in CI (`.github/workflows/trivy.yml`) and `make scan`.

`.github/workflows/ci.yml` runs the hooks and `tofu validate` (one matrix leg
per stack) on every PR, so neither depends on whoever remembered to install
the hook. Validate uses `-backend=false`: state is in Terraform Cloud and
validate does not need it, so the job needs no credentials.

`trivy.yml` already scans config weekly and uploads SARIF to the Security
tab. It is advisory — `.trivyignore` carries the accepted findings, each with
a reason.

`yamlfmt` skips `ansible/`: ansible-lint bundles its own yamllint and expects
the `---` document start that yamlfmt strips.

## Conventions

- **Every stack pins `required_version = ">= 1.6.0"`** and every provider it
  uses carries a version constraint in `required_providers`. A provider used
  but not declared means Terraform silently installs whatever is newest.
- **A declaration that is deliberately not wired up yet gets a
  `# tflint-ignore: terraform_unused_declarations` on the line directly above
  it, with a comment saying why.** The rule stays on so real dead code is
  still caught. Current cases: `kubernetes_worker_nodes` and
  `oci_containerengine_node_pool_option` in `oci-free-cloud-k8s` (the node-pool
  layout is still fixed in `k8s.tf`), and `schematic_file` in `talos`.
- **Secrets never land in the repo.** `kubeconfig`, `talosconfig` and
  `*.tfvars` are gitignored; values come from Terraform Cloud variables or the
  environment. `gitleaks` and `detect-private-key` are the backstop, not the
  rule.
- **`.trivyignore` needs a reason.** Each entry names the rule and why it does
  not apply (e.g. `AVD-GIT-0001`: repositories are intentionally public).
- **The OpenWrt playbook goes through `raw:`** because OpenWrt ships without
  python. Ordering in `openwrt-cloudflare-allowlist.yml` matters: fw4
  evaluates rules in config order, so the accept rule must precede the drop,
  and both are recreated on every run to keep that guaranteed.
