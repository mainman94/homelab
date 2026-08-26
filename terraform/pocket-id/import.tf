# One-time import of the Pocket ID state that existed before this module —
# clients, groups and users were all created by hand through the UI.
import {
  to = pocketid_group.this["homelab"]
  id = "5fd19418-4054-4905-bb97-1c77f9c3cec2"
}
import {
  to = pocketid_group.this["opencloud_spaceadmins"]
  id = "7d02d7fa-02d5-4e43-af65-1f4e9487c84f"
}
import {
  to = pocketid_group.this["admin"]
  id = "8e4a65dd-2369-4eee-bee2-63a0fc002c1c"
}

import {
  to = pocketid_client.this["argo-cd"]
  id = "9ef757ce-42bd-4c89-be46-3f0bbeff4509"
}
import {
  to = pocketid_client.this["opencloud"]
  id = "cc227522-08e4-45c4-8b33-47637d674452"
}
import {
  to = pocketid_client.this["opencloud-desktop"]
  id = "OpenCloudDesktop"
}
import {
  to = pocketid_client.this["opencloud-android"]
  id = "OpenCloudAndroid"
}
import {
  to = pocketid_client.this["opencloud-ios"]
  id = "OpenCloudIOS"
}
import {
  to = pocketid_client.this["gitea"]
  id = "4123dfc3-cac2-4639-ba61-188046e20605"
}
import {
  to = pocketid_client.this["kargo"]
  id = "bf4d7cd6-747d-45b8-b70c-55bfba255d09"
}
import {
  to = pocketid_client.this["vaultwarden"]
  id = "89f42ef9-8120-41f0-bfd5-b3ce2efca587"
}
import {
  to = pocketid_client.this["cloudflare_access"]
  id = "56540b0f-e214-49c4-b25a-954c6af5e8c8"
}
import {
  to = pocketid_client.this["audiobookshelf"]
  id = "405d667b-f766-4b7f-9cde-f075899f31bb"
}
import {
  to = pocketid_client.this["grafana"]
  id = "7a8642c3-f7a1-4790-ac28-8f14e00a2779"
}

# Slot order is alphabetical-by-username (see locals.users in main.tf):
# 0 = philippmatthias, 1 = pocketid_admin, 2 = sophie.
import {
  to = pocketid_user.this["0"]
  id = "a7145ee2-c742-4491-8ea9-7d89be4151dc"
}
import {
  to = pocketid_user.this["1"]
  id = "1e56504d-aeb6-46e0-b92b-4c36e303355b"
}
import {
  to = pocketid_user.this["2"]
  id = "34ef3d2c-df0f-455e-8a25-82b5d3d4857d"
}
