# Talos Bare-Metal Bootstrap

This directory is designed around a Terraform-first workflow for Talos on bare metal. It automates the generation of machine configurations, cluster secrets, and the initial bootstrap process.

It contains:

- the factory schematic embedded in [main.tf](main.tf)
- the shared cluster patch in [patch.yaml](patch.yaml)
- the Terraform configuration in [main.tf](main.tf)

## Target topology

The intended bare-metal cluster rollout follows a sequential approach for stability:

1. first `cp1` (Bootstrap node)
2. then `cp2` (Join to cluster)
3. then `cp3` (Establish etcd quorum)

The target topology consists of 3 control-plane nodes to ensure high availability and etcd quorum.

## Technical baseline

The schematic in [main.tf](main.tf) includes these essential extensions:

- `siderolabs/iscsi-tools`: Required for Longhorn and other storage providers.
- `siderolabs/nfs-utils`: For NFS mount support.
- `siderolabs/util-linux-tools`: General system utilities.

The shared patch in [patch.yaml](patch.yaml) applies these global settings:

- **NTP**: Configured via `at.pool.ntp.org`.
- **CNI**: No built-in CNI (`cni: none`). You MUST install a CNI (e.g., Cilium) after bootstrap.
- **Kube-proxy**: Disabled (`proxy.disabled: true`), intended for Cilium's kube-proxy replacement.
- **Scheduling**: Enabled on control planes (`allowSchedulingOnControlPlanes: true`), allowing workloads to run on these nodes without manual taint removal.

## Prerequisites

You need the following tools and infrastructure:

- `terraform`
- `talosctl`
- `kubectl`
- 1 to 3 bare-metal servers
- A static network environment with a Reserved API VIP (e.g., `192.168.0.10`)

## Networking & `lan0` Alias

The Terraform configuration uses a stable device alias `lan0`. It maps the physical NIC to this alias using the `interface_mac` provided in your variables. This ensures that even if OS-level device names change, the Talos configuration remains stable.

## Factory ID from the schematic

The Terraform configuration defines the schematic directly in [main.tf](main.tf) and uses the Talos provider to generate the factory ID via `talos_image_factory_schematic`.

You do not need to manage `schematic_id` manually. The Terraform output will display the `schematic_id` and the generated `installer_image`:

```bash
terraform output schematic_id
terraform output installer_image
```

If you modify the schematic in `main.tf`, Terraform will generate a new factory ID automatically.

## Step 1: Define Your Environment

Create your local configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Initially define only `cp1` to establish the cluster. Ensure `install_disk` and `data_disk` use stable identifiers (prefer `/dev/disk/by-id/...`).

## Step 2: Boot `cp1`

Boot `cp1` with the Talos factory ISO or via PXE. The installer image is built from the schematic defined in [main.tf](main.tf) and will be output after `terraform apply`.

## Step 3: Terraform Apply & Bootstrap

```bash
terraform init
terraform apply
```

This will:

- Register the schematic and derive the installer image.
- Generate cluster secrets and machine configs.
- Apply config to `cp1` and trigger the bootstrap.
- Export `talosconfig` and `kubeconfig` (marked as sensitive).

## Step 4: Verify Access

```bash
terraform output -raw talosconfig > talosconfig
terraform output -raw kubeconfig > kubeconfig

# Check Talos health
talosctl --talosconfig ./talosconfig -n <cp1_ip> health

# Check Kubernetes nodes
KUBECONFIG=./kubeconfig kubectl get nodes
```

Note: Nodes will stay `NotReady` until the CNI is installed.

## Step 5: Install Cilium (CNI)

Install Cilium with kube-proxy replacement. This setup uses KubePrism (accessing the API via `localhost:7445`).

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
  --set l2announcements.enabled=true
```

## Step 6: Install Longhorn (Storage)

Prepare the namespace and install Longhorn:

```bash
KUBECONFIG=./kubeconfig kubectl create namespace longhorn-system
KUBECONFIG=./kubeconfig kubectl label namespace longhorn-system \
  pod-security.kubernetes.io/enforce=privileged \
  --overwrite

KUBECONFIG=./kubeconfig helm repo add longhorn https://charts.longhorn.io
KUBECONFIG=./kubeconfig helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set defaultSettings.defaultDataPath=/var/mnt/longhorn \
  --set defaultSettings.defaultReplicaCount=3
```

## Step 7: Scaling the Cluster

Once `cp1` is healthy, add `cp2` and `cp3` to your `terraform.tfvars`. Boot them with the factory image and run `terraform apply`. Terraform will handle the configuration application and cluster join process.

## Operations

### Upgrading Talos

To upgrade Talos to a new version:

1. Update the `talos_version` in `variables.tf`:

   ```bash
   # Update talos_version in variables.tf
   sed -i 's/default = "v1.12.x"/default = "v1.13.0"/' variables.tf
   ```

2. Run `terraform plan` to see the new installer image:

   ```bash
   terraform plan
   ```

3. Get the new installer image from the Terraform output:

   ```bash
   terraform output -raw installer_image
   # Output: factory.talos.dev/metal-installer/<schematic>:v1.13.0
   ```

4. **Use `talosctl upgrade` instead of `terraform apply`** for a controlled, one-node-at-a-time upgrade:

   ```bash
   # Replace with your node IPs
   INSTALLER_IMAGE=$(terraform output -raw installer_image)

   # Upgrade each control plane node sequentially
   talosctl --talosconfig ./talosconfig upgrade \
     --nodes 192.168.0.53 \
     --image "$INSTALLER_IMAGE"

   talosctl --talosconfig ./talosconfig upgrade \
     --nodes 192.168.0.65 \
     --image "$INSTALLER_IMAGE"

   talosctl --talosconfig ./talosconfig upgrade \
     --nodes 192.168.0.101 \
     --image "$INSTALLER_IMAGE"
   ```

5. Verify the upgrade on each node:

   ```bash
   talosctl --talosconfig ./talosconfig -n 192.168.0.53 version
   # Should show the new Talos version
   ```

6. After all nodes are upgraded, run `terraform apply` to update the state:
   ```bash
   terraform apply
   ```

### Upgrading Kubernetes

To upgrade Kubernetes, update the `kubernetes_version` in `variables.tf`:

```bash
sed -i 's/default = "v1.35.x"/default = "v1.36.0"/' variables.tf
terraform apply
```

This will update the Kubernetes components on all nodes. Monitor the upgrade using `kubectl`.

### Extensions

To add or remove system extensions, modify the `schematic` block in [main.tf](main.tf). Find the `talos_image_factory_schematic` resource:

```hcl
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/iscsi-tools",
          "siderolabs/nfs-utils",
          "siderolabs/util-linux-tools"
        ]
      }
    }
  })
}
```

Add or remove extension IDs from the `officialExtensions` list. After modifying, run:

```bash
terraform plan
# Review the new installer_image and schematic_id
terraform apply
```

Then follow the Talos upgrade procedure to roll out the new extensions to your nodes.

### Maintenance

- Use `talosctl` for deep debugging and node operations.
- Use `kubectl` for cluster management.
- The source of truth for node configuration remains this Terraform project.
