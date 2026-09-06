#!/usr/bin/env bash
# PostToolUse: keep edited Terraform canonically formatted, so terraform_fmt
# never fails the commit hook on something an agent just wrote.
set -uo pipefail
f=$(jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0
case "$f" in
  *.tf|*.tftest.hcl) ;;
  *) exit 0 ;;
esac
tf=$(command -v terraform || command -v tofu) || exit 0
"$tf" fmt "$f" >/dev/null 2>&1 || true
exit 0
