variable "cluster_name" {
  description = "Name of the Talos/Kubernetes cluster."
  type        = string
  default     = "homelab"
}

variable "cluster_endpoint" {
  description = "VIP or load balancer endpoint for the Kubernetes API server."
  type        = string
  default     = "https://192.168.178.10:6443"
}

variable "controlplane_vip" {
  description = "Native Talos VIP used by the control plane nodes."
  type        = string
  default     = "192.168.178.10"
}

variable "network_interface" {
  description = "Network interface name used on all control plane nodes."
  type        = string
  default     = "eth0"
}

variable "longhorn_namespace" {
  description = "Namespace used by Longhorn."
  type        = string
  default     = "longhorn-system"
}

variable "longhorn_data_path" {
  description = "Host path used by Longhorn for data storage on Talos."
  type        = string
  default     = "/var/mnt/longhorn"
}

variable "nodes" {
  description = "Definition of the three Talos control plane nodes."
  type = map(object({
    hostname     = string
    ip           = string
    install_disk = string
  }))

  default = {
    node-1 = {
      hostname     = "talos-01"
      ip           = "192.168.178.11"
      install_disk = "/dev/sda"
    }
    node-2 = {
      hostname     = "talos-02"
      ip           = "192.168.178.12"
      install_disk = "/dev/sda"
    }
    node-3 = {
      hostname     = "talos-03"
      ip           = "192.168.178.13"
      install_disk = "/dev/sda"
    }
  }

  validation {
    condition     = contains([1, 3], length(var.nodes))
    error_message = "Please define either one or three nodes."
  }
}
