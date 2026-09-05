# homelab — Terraform stacks and Ansible playbooks for the homelab control plane.
#
# Runs happen in Terraform Cloud, so `plan`/`apply` here are for local
# inspection and for the stacks driven from a workstation (talos, imports).
# TF is `tofu` when OpenTofu is installed and `terraform` otherwise; override
# with `make TF=terraform ...`.

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

TF ?= $(shell command -v tofu 2>/dev/null || command -v terraform 2>/dev/null || echo terraform)
STACKS := $(patsubst terraform/%/,%,$(wildcard terraform/*/))

# `make plan STACK=cloudflare` narrows any per-stack target to one stack.
STACK ?=
TARGETS := $(if $(STACK),$(STACK),$(STACKS))

ANSIBLE_DIR := ansible
INVENTORY := $(ANSIBLE_DIR)/inventory/hosts.yml

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "  Per-stack targets take STACK=<name>, e.g. make plan STACK=cloudflare"
	@echo "  Stacks: $(STACKS)"

.PHONY: hooks
hooks: ## Install the git pre-commit hook
	pre-commit install

.PHONY: lint
lint: ## Run every pre-commit hook over the whole tree
	pre-commit run --all-files

.PHONY: fmt
fmt: ## Rewrite Terraform files to canonical format
	$(TF) fmt -recursive

# --- terraform ---------------------------------------------------------------

.PHONY: init
init: ## terraform init each stack
	@for s in $(TARGETS); do \
		echo "==> init $$s"; \
		$(TF) -chdir=terraform/$$s init -input=false; \
	done

.PHONY: validate
validate: ## terraform validate each stack (no backend, no credentials)
	@for s in $(TARGETS); do \
		echo "==> validate $$s"; \
		$(TF) -chdir=terraform/$$s init -backend=false -input=false >/dev/null; \
		$(TF) -chdir=terraform/$$s validate; \
	done

.PHONY: plan
plan: ## terraform plan a stack (needs credentials)
	@test -n "$(STACK)" || { echo "error: STACK is not set — e.g. make plan STACK=cloudflare" >&2; exit 1; }
	$(TF) -chdir=terraform/$(STACK) plan

.PHONY: apply
apply: ## terraform apply a stack (needs credentials)
	@test -n "$(STACK)" || { echo "error: STACK is not set — e.g. make apply STACK=cloudflare" >&2; exit 1; }
	$(TF) -chdir=terraform/$(STACK) apply

.PHONY: lint-deep
lint-deep: ## tflint including provider rulesets (fetches plugins)
	@for s in $(TARGETS); do \
		echo "==> tflint $$s"; \
		tflint --chdir=terraform/$$s --config="$(CURDIR)/.tflint.hcl" --init; \
		tflint --chdir=terraform/$$s --config="$(CURDIR)/.tflint.hcl"; \
	done

.PHONY: security
security: ## trivy config scan, the same one CI runs
	@command -v trivy >/dev/null || { echo "trivy not on PATH — see .devcontainer" >&2; exit 1; }
	trivy config --exit-code 1 .

# --- ansible -----------------------------------------------------------------

.PHONY: ansible-lint
ansible-lint: ## Lint the playbooks
	pre-commit run ansible-lint --all-files

.PHONY: ansible-check
ansible-check: ## Dry-run the Cloudflare allowlist playbook against the router
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/openwrt-cloudflare-allowlist.yml --check

.PHONY: ansible-run
ansible-run: ## Apply the Cloudflare allowlist playbook to the router
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/openwrt-cloudflare-allowlist.yml

# --- meta --------------------------------------------------------------------

.PHONY: check
check: lint validate ## Everything a PR needs to pass

.PHONY: clean
clean: ## Remove downloaded providers
	rm -rf terraform/*/.terraform

.PHONY: update-hooks
update-hooks: ## Bump pinned hook revisions
	pre-commit autoupdate
