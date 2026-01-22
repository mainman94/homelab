variable "compartment_id" {
  type        = string
  description = "The compartment to create the resources in"
}

variable "region" {
  description = "OCI region"
  type        = string

  default = "eu-zurich-1"
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID"
  type        = string
}

variable "fingerprint" {
  description = "API key fingerprint for the OCI user"
  type        = string
}

variable "private_key" {
  description = "OCI API private key content (use TF_VAR_private_key in Terraform Cloud)"
  type        = string
  sensitive   = true
}

variable "kubernetes_version" {
  # https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengaboutk8sversions.htm
  description = "Version of Kubernetes"
  type        = string

  default = "v1.34.1"
}

variable "kubernetes_worker_nodes" {
  description = "Worker node count"
  type        = number
  default     = 2
}

