# Core ruleset only. The provider rulesets (tflint-ruleset-google, -aws, …)
# have to be fetched with `tflint --init` on every run, which is too slow and
# too network-dependent for a commit hook. `make lint-deep` runs those.
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
