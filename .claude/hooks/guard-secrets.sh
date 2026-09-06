#!/usr/bin/env bash
# PreToolUse: block edits to credential-bearing or state files.
# Exit 2 = block the tool call (the stderr message is shown to Claude).
#
# Every stack here reaches live infrastructure, and the ones that need
# secrets read them from OpenBao through an ephemeral block so the value never
# touches state. A real value pasted into a tfvars file would undo that and be
# committed to a public repo.
set -uo pipefail
f=$(jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0
case "$f" in
  *.tfvars.example) exit 0 ;;
  *.tfvars|*.tfvars.json)
    echo "Blocked: '$f' holds real values and is git-ignored. Edit the .example, or do it manually." >&2
    exit 2 ;;
  *.tfstate|*.tfstate.*)
    echo "Blocked: state lives in Terraform Cloud and is never edited by hand." >&2
    exit 2 ;;
  *settings.local.json|*.env)
    echo "Blocked: '$f' holds local credentials — edit it manually, not via Claude." >&2
    exit 2 ;;
esac
exit 0
