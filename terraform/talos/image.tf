# Image Factory: which extensions go into the installer, and the URLs for every
# asset derived from that schematic.

# Resolves each requested extension against the factory's official catalogue
# for this exact Talos version. `exact_filters` matches the full factory name,
# so `siderolabs/nfs-utils` cannot quietly match some other `nfs-*` extension
# the way the substring `filters` would.
data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_version

  exact_filters = {
    names = var.system_extensions
  }
}

locals {
  requested_extensions = sort(var.system_extensions)

  # Sorted so the schematic YAML — and therefore the schematic ID and the
  # installer image — does not depend on the order the factory replies in.
  resolved_extensions = sort([
    for extension in data.talos_image_factory_extensions_versions.this.extensions_info : extension.name
  ])

  missing_extensions = setsubtract(local.requested_extensions, local.resolved_extensions)
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = local.resolved_extensions
      }
    }
  })

  # A filter that matches nothing returns nothing rather than failing, so
  # without this an extension that was renamed or dropped in a newer Talos
  # release would produce a valid schematic with the extension missing. That
  # surfaces as Longhorn failing to attach volumes on a node that upgraded
  # cleanly — this turns it into a plan error instead.
  lifecycle {
    precondition {
      condition = length(local.missing_extensions) == 0
      error_message = format(
        "The Image Factory has no official extension named %s for Talos %s. Check https://factory.talos.dev for the names it publishes for that version.",
        join(", ", local.missing_extensions),
        var.talos_version,
      )
    }
  }
}

# Pure URL construction in the provider — no factory call — so this costs
# nothing and replaces hand-assembled `factory.talos.dev/...` strings that had
# to be kept in step with the factory's path layout by hand.
data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "metal"
  architecture  = var.architecture
}
