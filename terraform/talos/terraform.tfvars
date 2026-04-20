cluster_name     = "talos-bm"
cluster_endpoint = "https://192.168.0.10:6443"
cluster_vip      = "192.168.0.10"
gateway          = "192.168.0.2"

talos_version      = "v1.12.6"
kubernetes_version = "v1.35.2"

controlplane_nodes = {
  cp1 = {
    management_ip        = "192.168.0.53"
#    node_name            = "eggenberg-talos-cp1-nb1"
    install_disk         = "/dev/disk/by-id/ata-MTFDDAV256TBN-1AR15ABHA_UFZNP01ZR93K4D"
    interface            = "enp0s31f6"
    address_cidr         = "192.168.0.53/24"
    data_disk            = "/dev/disk/by-id/ata-ST1000LM024_HN-M101MBB_S2ZWJ9KG905983"
    data_disk_mountpoint = "/var/mnt/longhorn"
  }
}
