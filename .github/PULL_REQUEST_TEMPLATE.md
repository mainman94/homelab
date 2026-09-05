## What

<!-- One or two sentences. -->

## Why

<!-- The problem this solves. Link the issue if there is one. -->

## Plan

<!-- What `make plan STACK=<name>` shows this will change. Paste the summary
     line, or say "no infrastructure change" for a docs/tooling PR. -->

## Checklist

- [ ] `make check` passes (hooks + `tofu validate` on every stack)
- [ ] Any new or changed provider carries a version constraint in
      `required_providers`
- [ ] Ansible change dry-run against the router (`make ansible-check`)
- [ ] No credentials, `kubeconfig`, `talosconfig` or `*.tfvars` in the diff
