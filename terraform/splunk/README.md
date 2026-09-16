# splunk

Manages Splunk Observability Cloud (realm `eu0`) as a Terraform Cloud
workspace: dashboard group and cluster-overview dashboard for
`eggenberg-talos-cluster-1`, fed by the `splunk-otel-collector` deployment.

## Setup

1. In Splunk Observability Cloud: Settings -> Access Tokens -> create an org
   token with the **API** permission (the ingest-only token used by the otel
   collector does not have this).
2. `bao kv patch homelab/prod/splunk ADMIN_ACCESS_TOKEN=<token>` — adds
   `ADMIN_ACCESS_TOKEN` alongside the existing `ACCESS_TOKEN` property.
   The portfolio ExternalSecret maps the existing `ADMIN_TOKEN` property to
   its server-side `SPLUNK_ACCESS_TOKEN`; no token value belongs in Git.
3. Apply `terraform/tfe` first so the `splunk` workspace, its
   `TFC_VAULT_*` env vars, and the OpenBao `tfc-splunk` JWT role exist.
4. Apply this stack (via the TFC workspace, not locally — see backend.tf).

## Adding charts

Add a `signalfx_time_chart` resource with a SignalFlow `program_text`, then
reference its `chart_id` in a `chart` block on `signalfx_dashboard.cluster_overview`.
