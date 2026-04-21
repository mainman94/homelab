variable "cluster_name" {
  description = "Talos/Kubernetes cluster name."
  type        = string
  default     = "talos-bm"
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint including scheme and port."
  type        = string
}

variable "cluster_vip" {
  description = "Virtual IP used by the control plane nodes."
  type        = string
}

variable "gateway" {
  description = "Default IPv4 gateway for all nodes."
  type        = string
}

variable "talos_version" {
  description = "Talos version used for the factory installer image."
  type        = string
  default     = "v1.12.6"
}

variable "kubernetes_version" {
  description = "Target Kubernetes version."
  type        = string
  default     = "v1.35.2"
}

variable "schematic_file" {
  description = "Path to the Talos Image Factory schematic file."
  type        = string
  default     = "schematic.yaml"
}

variable "common_config_patch_file" {
  description = "Path to the shared Talos config patch."
  type        = string
  default     = "patch.yaml"
}

variable "controlplane_nodes" {
  description = "Bare-metal control plane nodes. Start with cp1, then add cp2 and cp3 over time."
  type = map(object({
    management_ip        = string
    node_name            = optional(string)
    install_disk         = string
    interface_mac        = string
    address_cidr         = string
    data_disk            = optional(string)
    data_disk_mountpoint = optional(string, "/var/mnt/longhorn")
  }))

  validation {
    condition     = contains(keys(var.controlplane_nodes), "cp1")
    error_message = "controlplane_nodes must contain at least the cp1 entry."
  }

  validation {
    condition     = length(var.controlplane_nodes) >= 1 && length(var.controlplane_nodes) <= 3
    error_message = "controlplane_nodes must contain between 1 and 3 nodes."
  }
}
