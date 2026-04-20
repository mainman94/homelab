# OCI Free Cloud Kubernetes Stack

This stack provisions an Oracle Cloud Infrastructure Kubernetes environment aimed at the OCI free-tier footprint.

## What it manages

The current configuration creates:

- a VCN named `k8s-vcn`
- one public subnet for the Kubernetes API and load balancer exposure
- one private subnet for worker nodes
- security lists for the public subnet, private subnet, and network load balancer traffic
- an OKE cluster named `k8s-cluster`
- two ARM-based node pools distributed across availability domains
- a local kubeconfig file written to `../.kube.config`

## Required inputs

The provider requires:

- `compartment_id`
- `tenancy_ocid`
- `user_ocid`
- `fingerprint`
- `private_key`

Optional inputs with defaults include:

- `region`
- `kubernetes_version`
- `kubernetes_worker_nodes`

## Usage

1. In Terraform Cloud, set the required OCI credentials for the `oci-free-cloud-k8s` workspace.
2. For local runs, export the same values in your shell or provide them through a local `.tfvars` file that is not committed.
3. Run `terraform init` in this directory.
4. Review changes with `terraform plan`.
5. Apply with `terraform apply` once the plan is correct.

## Terraform Cloud backend

This stack uses the remote Terraform backend in the `eggenberg-homelab` organization and the `oci-free-cloud-k8s` workspace.

## Notes

- The node-pool layout is currently defined directly in [k8s.tf](k8s.tf) as two fixed pools rather than being driven by `kubernetes_worker_nodes`.
- The stack writes a kubeconfig file locally through the `local_file` resource, which is convenient for local use but should be reviewed carefully for remote-run workflows.
- Network CIDRs and security-list rules are currently hard-coded in the root module.
