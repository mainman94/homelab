#!/usr/bin/env bash
# Provision the dev container. Everything the repo needs is pinned in
# mise.toml — terraform, tflint, python, pre-commit, actionlint, shellcheck,
# trivy — so this installs mise and lets it do the rest. Ansible stays a
# devcontainer feature: `make ansible-run` needs it, and the pre-commit
# ansible-lint hook brings its own ansible-core anyway. CI installs from the
# same mise.toml.
set -euo pipefail

echo "==> installing mise"
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# Activate for interactive shells so the pinned binaries are on PATH.
for shell in bash zsh; do
  rc="$HOME/.${shell}rc"
  [ -f "$rc" ] || continue
  grep -q "mise activate" "$rc" || echo "eval \"\$(mise activate $shell)\"" >> "$rc"
done

echo "==> installing the pinned toolchain (terraform, tflint, python, pre-commit, actionlint, shellcheck, trivy)"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mise trust
mise install

echo "==> installing the git hook"
mise exec -- pre-commit install

echo "==> warming hook environments"
mise exec -- pre-commit install-hooks

cat <<'MSG'

homelab dev container ready.

  make help                 list every target
  make check                hooks + terraform validate across every stack
  make plan STACK=cloudflare  one stack (needs credentials)

Terraform, not OpenTofu: four stacks use `ephemeral` blocks, which OpenTofu
does not implement.

Terraform Cloud holds the state; nothing here is configured to run applies
on its own.
MSG
