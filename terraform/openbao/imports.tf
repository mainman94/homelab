# prod/contact predates this stack and holds live values (the per-env Postgres
# passwords the pmhme contact app reads through ESO). Import it instead of
# letting Terraform create it: a create would write an empty data_json and wipe
# the secret. Remove this file once the apply has gone through.

import {
  to = vault_kv_secret_v2.prod["contact"]
  id = "homelab/data/prod/contact"
}
