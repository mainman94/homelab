# Talos Bare-Metal Bootstrap

This directory is designed around a Terraform-first workflow for Talos on bare metal.

It contains:

- the factory schematic in [schematic.yaml](schematic.yaml)
- the shared cluster patch in [patch.yaml](patch.yaml)
- the Terraform configuration in [main.tf](main.tf)

Previously generated Talos machine configs such as `controlplane.yaml` and `worker.yaml` are not part of the recommended workflow in this directory.

## Target topology

The intended bare-metal cluster rollout is:

1. first `cp1`
2. then `cp2`
3. then `cp3`

The target topology is therefore:

- `cp1`: control plane
- `cp2`: control plane
- `cp3`: control plane

This gives you a working cluster first and then expands it to a 3-node control-plane setup with etcd quorum and API HA.

## Technical baseline

The schematic in [schematic.yaml](schematic.yaml) includes these extensions:

- `siderolabs/iscsi-tools`
- `siderolabs/nfs-utils`
- `siderolabs/util-linux-tools`

The shared patch in [patch.yaml](patch.yaml) sets:

- no built-in CNI
- `kube-proxy` disabled

That means you must install a CNI with kube-proxy replacement immediately after bootstrap, typically Cilium.

## Prerequisites

You need:

- `terraform`
- `talosctl`
- `kubectl`
- 1 to 3 bare-metal servers
- a network with static IPs
- ideally an API VIP, for example `192.168.0.10`

Example:

- `cp1`: `192.168.0.11`
- `cp2`: `192.168.0.12`
- `cp3`: `192.168.0.13`
- `cluster endpoint / VIP`: `192.168.0.10`
- `gateway`: `192.168.0.2`

## Factory ID from the schematic

The Terraform configuration uses Talos provider `0.10.x` and generates the factory ID directly from [schematic.yaml](schematic.yaml) via `talos_image_factory_schematic`.

You do not need to manage `schematic_id` manually in Terraform.

If you still want to inspect the ID in advance, there are two options:

1. in the Talos Image Factory in the browser
2. through an API call with `curl`

Example:

```bash
curl -X POST \
  -H "Content-Type: application/yaml" \
  --data-binary @schematic.yaml \
  https://factory.talos.dev/schematics
```

The response contains the generated schematic ID.

## Terraform structure

The actual cluster management lives in:

- [versions.tf](versions.tf)
- [variables.tf](variables.tf)
- [main.tf](main.tf)
- [outputs.tf](outputs.tf)
- [terraform.tfvars.example](terraform.tfvars.example)

The configuration does the following:

- registers the schematic from [schematic.yaml](schematic.yaml)
- generates cluster secrets
- generates Talos machine configs from those secrets
- patches networking plus install and data disks per node
- applies the configuration to the nodes
- bootstraps `cp1`
- exposes `talosconfig` and `kubeconfig` as Terraform outputs

## Important variables

The most important inputs are shown in [terraform.tfvars.example](terraform.tfvars.example):

- `cluster_endpoint`
- `cluster_vip`
- `gateway`
- `talos_version`
- `kubernetes_version`
- `controlplane_nodes`

`kubernetes_version` is not derived automatically from Talos. It is passed explicitly to `talos_machine_configuration` in [main.tf](main.tf), which keeps the target version explicit and reproducible.

## Step 1: define `cp1`

First create your local working file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Initially define only `cp1`:

```hcl
cluster_name     = "talos-bm"
cluster_endpoint = "https://192.168.0.10:6443"
cluster_vip      = "192.168.0.10"
gateway          = "192.168.0.2"

talos_version      = "v1.12.6"
kubernetes_version = "v1.35.2"

controlplane_nodes = {
  cp1 = {
    management_ip = "192.168.0.11"
    node_name     = "cp1"
    install_disk  = "/dev/sdc"
    interface     = "enp0s31f6"
    address_cidr  = "192.168.0.11/24"
    data_disk     = "/dev/sdb"
    # optional, default: /var/mnt/longhorn
    data_disk_mountpoint = "/var/mnt/longhorn"
  }
}
```

Important:

- `install_disk` must match the real bare-metal host
- `interface` must match the real NIC name
- `cluster_endpoint` should point to your VIP
- `node_name` is optional and sets the Talos and Kubernetes node name
- `data_disk` is optional per node and is used for Longhorn data

Formatting and provisioning of `data_disk`:

- Talos provisions the extra disk when the machine config is applied, if the disk is not already provisioned as required.
- During that process, the partition is created and mounted at the configured mount point.
- For stability, prefer `/dev/disk/by-id/...` over `/dev/sdX`.

## Step 2: boot `cp1` with the factory image

Boot only `cp1` with the Talos factory ISO or via PXE.

The boot image must be built from the schematic in [schematic.yaml](schematic.yaml) so the extensions are included in the installer.

If `cp1` is reachable in maintenance mode, you can optionally verify that with:

```bash
talosctl -n 192.168.0.11 version
```

## Step 3: initialize Terraform and bootstrap `cp1`

```bash
terraform init
terraform apply
```

This does the following:

- generates the factory ID from the schematic
- derives the installer image from it
- generates Talos secrets
- builds the machine configuration for `cp1`
- applies the configuration to `cp1`
- bootstraps `cp1`
- exposes `talosconfig` and `kubeconfig` as outputs

## Step 4: verify access

Fetch the Talos config from Terraform:

```bash
terraform output -raw talosconfig > talosconfig
```

Fetch the kubeconfig from Terraform:

```bash
terraform output -raw kubeconfig > kubeconfig
```

Check the cluster:

```bash
talosctl --talosconfig ./talosconfig -n 192.168.0.11 health
KUBECONFIG=./kubeconfig kubectl get nodes
```

Immediately after bootstrap, the node will not be fully `Ready` without a CNI. That is expected in this setup.

## Step 5: install the CNI

Because [patch.yaml](patch.yaml) sets `cni: none` and `proxy.disabled: true`, install a CNI with kube-proxy replacement right after bootstrap.

Typically Cilium:

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update
KUBECONFIG=./kubeconfig helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --create-namespace \
  --version 1.19.2 \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445 \
  --set operator.replicas=1 \
  --set gatewayAPI.enabled=true \
  --set gatewayAPI.enableAlpn=true \
  --set gatewayAPI.enableAppProtocol=true \
  --set l2announcements.enabled=true
```

Then check again:

```bash
KUBECONFIG=./kubeconfig kubectl get nodes
KUBECONFIG=./kubeconfig kubectl -n kube-system get pods
```

## Step 6: install Longhorn

For Longhorn, first create the namespace and set it to `privileged`:

```bash
KUBECONFIG=./kubeconfig kubectl create namespace longhorn-system
KUBECONFIG=./kubeconfig kubectl label namespace longhorn-system \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged \
  --overwrite
```

Then install Longhorn through Helm, using one replica for a `cp1`-only setup:

```bash
KUBECONFIG=./kubeconfig helm repo add longhorn https://charts.longhorn.io
KUBECONFIG=./kubeconfig helm repo update
KUBECONFIG=./kubeconfig helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set defaultSettings.defaultDataPath=/var/mnt/longhorn \
  --set defaultSettings.defaultReplicaCount=1
```

Check status:

```bash
KUBECONFIG=./kubeconfig kubectl -n longhorn-system get pods
KUBECONFIG=./kubeconfig kubectl get sc
```

## Step 7: migration smoke test on `cp1` (optional, recommended)

Before adding `cp2` and `cp3`, you can already validate workloads and migration paths on a single-node cluster.

If workloads do not schedule because of the control-plane taint, temporarily remove it for the test:

```bash
KUBECONFIG=./kubeconfig kubectl taint nodes cp1 node-role.kubernetes.io/control-plane-
```

Example smoke test:

```bash
KUBECONFIG=./kubeconfig kubectl create ns migration-smoke
KUBECONFIG=./kubeconfig kubectl -n migration-smoke create deploy echo --image=nginx:stable
KUBECONFIG=./kubeconfig kubectl -n migration-smoke expose deploy echo --port=80 --type=ClusterIP
KUBECONFIG=./kubeconfig kubectl -n migration-smoke rollout status deploy/echo
KUBECONFIG=./kubeconfig kubectl -n migration-smoke get pods,svc,endpoints
```

Clean up after the test:

```bash
KUBECONFIG=./kubeconfig kubectl delete ns migration-smoke
```

## Step 8: add `cp2`

Once `cp1` is stable, add `cp2` in [terraform.tfvars.example](terraform.tfvars.example) or in your local `terraform.tfvars`:

```hcl
controlplane_nodes = {
  cp1 = {
    management_ip = "192.168.0.11"
    node_name     = "cp1"
    install_disk  = "/dev/sdc"
    interface     = "enp0s31f6"
    address_cidr  = "192.168.0.11/24"
    data_disk     = "/dev/sdb"
  }
  cp2 = {
    management_ip = "192.168.0.12"
    node_name     = "cp2"
    install_disk  = "/dev/sdc"
    interface     = "enp0s31f6"
    address_cidr  = "192.168.0.12/24"
    data_disk     = "/dev/sdb"
  }
}
```

Boot `cp2` with the same factory image and then run:

```bash
terraform apply
```

Terraform will then generate only the additional configuration for `cp2` and join the node to the existing cluster.

## Step 9: add `cp3`

After that, do the same for `cp3`:

```hcl
controlplane_nodes = {
  cp1 = {
    management_ip = "192.168.0.11"
    node_name     = "cp1"
    install_disk  = "/dev/sdc"
    interface     = "enp0s31f6"
    address_cidr  = "192.168.0.11/24"
    data_disk     = "/dev/sdb"
  }
  cp2 = {
    management_ip = "192.168.0.12"
    node_name     = "cp2"
    install_disk  = "/dev/sdc"
    interface     = "enp0s31f6"
    address_cidr  = "192.168.0.12/24"
    data_disk     = "/dev/sdb"
  }
  cp3 = {
    management_ip = "192.168.0.13"
    node_name     = "cp3"
    install_disk  = "/dev/sdc"
    interface     = "enp0s31f6"
    address_cidr  = "192.168.0.13/24"
    data_disk     = "/dev/sdb"
  }
}
```

Then run:

```bash
terraform apply
```

## Operations

From this point on, you should manage configuration changes through Terraform rather than manually on the nodes.

Typical changes:

- add new control-plane nodes
- adjust disk or network parameters
- upgrade `talos_version`
- deliberately raise `kubernetes_version`
- extend the schematic and derive a new installer image from it

`talosctl` is still useful for debugging, but the desired state should live in Terraform.
