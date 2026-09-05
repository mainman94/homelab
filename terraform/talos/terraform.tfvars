cluster_name     = "talos-bm"
cluster_endpoint = "https://192.168.0.10:6443"
cluster_vip      = "192.168.0.10"
gateway          = "192.168.0.2"

controlplane_nodes = {
  cp1 = {
    management_ip = "192.168.0.53"
    #    node_name            = "eggenberg-talos-cp1-nb1"
    install_disk         = "/dev/disk/by-id/ata-MTFDDAV256TBN-1AR15ABHA_UFZNP01ZR93K4D"
    interface_mac        = "80:ce:62:2a:c2:32"
    address_cidr         = "192.168.0.53/24"
    data_disk            = "/dev/disk/by-id/ata-ST1000LM024_HN-M101MBB_S2ZWJ9KG905983"
    data_disk_mountpoint = "/var/mnt/longhorn"
  },
  cp2 = {
    management_ip = "192.168.0.65"
    #node_name     = "eggenberg-talos-cp1-elitedesk-1"
    install_disk  = "/dev/sdb"
    interface_mac = "bc:e9:2f:87:15:c4"
    address_cidr  = "192.168.0.65/24"
  },
  cp3 = {
    management_ip = "192.168.0.101"
    #node_name     = "eggenberg-talos-cp1-elitedesk-2"
    install_disk  = "dev/nvme0n1"
    interface_mac = "c4:65:16:9a:21:4f"
    address_cidr  = "192.168.0.101/24"
  }
}
