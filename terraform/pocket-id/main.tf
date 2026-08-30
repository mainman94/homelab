# Groups. Not sensitive — safe to declare in git. opencloud_role custom claims
# drive opencloud's PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM role mapping.
locals {
  groups = {
    homelab               = { friendly_name = "Homelab" }
    admin                 = { friendly_name = "Admin" }
    opencloud_spaceadmins = { friendly_name = "opencloud_spaceadmins", custom_claims = { opencloud_role = "opencloudSpaceAdmin" } }
  }
}

resource "pocketid_group" "this" {
  for_each = local.groups

  name          = each.key
  friendly_name = each.value.friendly_name
  custom_claims = try(each.value.custom_claims, null)
}

# OIDC clients for every app that authenticates against Pocket ID. Not
# sensitive — callback URLs and group restrictions are public app config.
locals {
  clients = {
    argo-cd = {
      client_id     = "9ef757ce-42bd-4c89-be46-3f0bbeff4509"
      callback_urls = ["https://argo.hauptmann.dev/api/dex/callback", "https://localhost:8085/auth/callback"]
      launch_url    = "https://argo.hauptmann.dev"
      groups        = ["homelab"]
    }
    opencloud = {
      client_id            = "cc227522-08e4-45c4-8b33-47637d674452"
      callback_urls        = ["https://cloud.hauptmann.dev/oidc-callback.html", "https://cloud.hauptmann.dev", "https://cloud.hauptmann.dev/oidc-silent-redirect.html"]
      logout_callback_urls = ["https://cloud.hauptmann.dev"]
      launch_url           = "https://cloud.hauptmann.dev"
      is_public            = true
      pkce_enabled         = true
      groups               = ["homelab", "opencloud_spaceadmins"]
    }
    opencloud-desktop = {
      client_id     = "OpenCloudDesktop"
      name          = "OpenCloud Desktop"
      callback_urls = ["http://127.0.0.1", "http://localhost"]
      launch_url    = "https://cloud.hauptmann.dev"
      is_public     = true
      pkce_enabled  = true
    }
    opencloud-android = {
      client_id     = "OpenCloudAndroid"
      name          = "OpenCloud Android"
      callback_urls = ["oc://android.opencloud.eu"]
      launch_url    = "https://cloud.hauptmann.dev"
      is_public     = true
      pkce_enabled  = true
    }
    opencloud-ios = {
      client_id     = "OpenCloudIOS"
      name          = "OpenCloud iOS"
      callback_urls = ["oc://ios.opencloud.eu"]
      launch_url    = "https://cloud.hauptmann.dev"
      is_public     = true
      pkce_enabled  = true
    }
    gitea = {
      client_id     = "4123dfc3-cac2-4639-ba61-188046e20605"
      name          = "git.hauptmann.dev"
      callback_urls = ["https://git.hauptmann.dev/user/oauth2/openid/Gitea", "https://git.hauptmann.dev/user/oauth2/pocketid/callback"]
      launch_url    = "https://git.hauptmann.dev"
      groups        = ["homelab"]
    }
    kargo = {
      client_id     = "bf4d7cd6-747d-45b8-b70c-55bfba255d09"
      name          = "Kargo"
      callback_urls = ["https://kargo.hauptmann.dev/login", "http://localhost/auth/callback"]
      launch_url    = "https://kargo.hauptmann.dev/login"
      is_public     = true
      pkce_enabled  = true
      groups        = ["homelab"]
    }
    vaultwarden = {
      client_id            = "89f42ef9-8120-41f0-bfd5-b3ce2efca587"
      name                 = "Vaulwarden"
      callback_urls        = ["https://passwords.hauptmann.dev/identity/connect/oidc-signin"]
      logout_callback_urls = ["https://passwords.hauptmann.dev"]
      launch_url           = "https://passwords.hauptmann.dev"
      pkce_enabled         = true
      groups               = ["homelab"]
    }
    cloudflare_access = {
      client_id     = "56540b0f-e214-49c4-b25a-954c6af5e8c8"
      name          = "Cloudflare"
      callback_urls = ["https://eggenberg-hauptmann.cloudflareaccess.com/cdn-cgi/access/callback"]
      launch_url    = "https://eggenberg-hauptmann.cloudflareaccess.com"
      groups        = ["homelab"]
    }
    audiobookshelf = {
      client_id     = "405d667b-f766-4b7f-9cde-f075899f31bb"
      name          = "Audiobookshelf"
      callback_urls = ["https://audiobookshelf.hauptmann.dev/audiobookshelf/auth/openid/mobile-redirect", "https://audiobookshelf.hauptmann.dev/audiobookshelf/auth/openid/callback"]
      launch_url    = "https://audiobookshelf.hauptmann.dev"
      groups        = ["homelab", "admin"]
    }
    grafana = {
      client_id     = "7a8642c3-f7a1-4790-ac28-8f14e00a2779"
      name          = "Grafana"
      callback_urls = ["https://grafana.hauptmann.dev/login/generic_oauth"]
      launch_url    = "https://grafana.hauptmann.dev"
      groups        = ["homelab"]
    }
    dockhand = {
      name          = "Dockhand"
      callback_urls = ["https://dockhand.hauptmann.dev/api/auth/oidc/callback"]
      launch_url    = "https://dockhand.hauptmann.dev"
      is_public     = false
      pkce_enabled  = true
      groups        = ["homelab"]
    }
  }
}

resource "pocketid_client" "this" {
  for_each = local.clients

  client_id            = try(each.value.client_id, null)
  name                 = try(each.value.name, each.key)
  callback_urls        = each.value.callback_urls
  logout_callback_urls = try(each.value.logout_callback_urls, [])
  launch_url           = each.value.launch_url
  is_public            = try(each.value.is_public, false)
  pkce_enabled         = try(each.value.pkce_enabled, false)
  allowed_user_groups  = [for g in try(each.value.groups, []) : pocketid_group.this[g].id]
}

# Users hold PII (email, real names) — kept out of git in a Vault secret
# instead of declared here. See terraform/openbao/README.md for the
# `bao kv put homelab/prod/pocket-id-users` shape.
#
# Not ephemeral: pocketid_user persists email/name to state regardless, so
# there's no benefit to fetching it ephemerally.
data "vault_kv_secret_v2" "pocket_id_users" {
  mount = "homelab"
  name  = "prod/pocket-id-users"
}

locals {
  # values() sorts by key (alphabetical on the username), so slot order below
  # is: philippmatthias, pocketid_admin, sophie.
  users             = [for u in jsondecode(data.vault_kv_secret_v2.pocket_id_users.data["USERS_JSON"]) : u]
  users_by_username = { for u in local.users : u.key => u }

  # for_each on the resource below must be resolvable without reading the
  # Vault data source (import blocks can't match instances otherwise), so it
  # iterates this static index instead of local.users_by_username directly.
  # ponytail: bump if a 4th user is ever added.
  user_slots = toset(["0", "1", "2"])
}

resource "pocketid_user" "this" {
  for_each = local.user_slots

  username   = values(local.users_by_username)[tonumber(each.key)].username
  email      = values(local.users_by_username)[tonumber(each.key)].email
  first_name = values(local.users_by_username)[tonumber(each.key)].first_name
  last_name  = values(local.users_by_username)[tonumber(each.key)].last_name
  is_admin   = values(local.users_by_username)[tonumber(each.key)].is_admin
  disabled   = values(local.users_by_username)[tonumber(each.key)].disabled
  groups     = [for g in values(local.users_by_username)[tonumber(each.key)].groups : pocketid_group.this[g].id]

  lifecycle {
    ignore_changes = [email_verified]
  }
}
