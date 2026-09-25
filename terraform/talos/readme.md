# Talos Bare-Metal Bootstrap

Terraform-first bootstrap for the bare-metal Talos control plane: it registers
the Image Factory schematic, generates the cluster secrets and per-node machine
configurations, applies them, bootstraps etcd and hands back a `talosconfig`
and `kubeconfig`.

| File                | What lives there                                        |
| ------------------- | ------------------------------------------------------- |
| `image.tf`          | Image Factory schematic and the asset URLs it produces  |
| `config.tf`         | Shared and per-node config patches, config generation   |
| `main.tf`           | Secrets, apply, bootstrap, health gate, kubeconfig      |
| `patch.yaml`        | The shared cluster patch                                |
| `variables.tf`      | Inputs, with the validation that guards the node map    |
| `tests/`            | `terraform test` suite over that validation             |

State is in Terraform Cloud; the runs happen from a workstation, because the
nodes are on the LAN and a remote runner cannot reach them.

**Always apply this stack with `terraform apply -parallelism=1`.**
`talos_machine` has no equivalent to the old `apply_mode =
"staged_if_needing_reboot"` — a config change that needs a reboot applies, and
reboots the node, immediately. With `controlplane` a `for_each` over up to
three nodes, default parallelism could reboot all three control-plane nodes
in the same apply and take etcd quorum with it.

## Versions

| Component             | Pinned at | Where                          |
| --------------------- | --------- | ------------------------------ |
| Talos Linux           | `v1.14.1` | `var.talos_version`            |
| Machine config contract | `v1.14` | `var.machine_config_contract`  |
| Kubernetes            | `v1.36.4` | `var.kubernetes_version`       |
| `siderolabs/talos`    | `~> 0.12.0` | `versions.tf`                |

The provider constraint is `~> 0.12.0`, not `~> 0.12`. The provider is
pre-1.0, so a minor bump is a breaking change, and `~> 0.12` would allow
anything below 1.0 and pull that in on the next `init -upgrade`.

0.12 also added `talos_cluster`, meant to eventually replace
`talos_machine_bootstrap` + `data.talos_cluster_health`. Not adopted here yet:
it's new in this same release with no documented `terraform import` path for
an already-bootstrapped cluster, unlike `talos_machine_bootstrap` (see
"Operations" below), so adding it fresh to state risks re-triggering
bootstrap. Revisit once the provider documents a migration path.

Kubernetes 1.37 is released and supported by Talos 1.14, which defaults to it.
This stack stays on 1.36 because `kubernetes_version` is applied by
`terraform apply`: bumping the minor upgrades the live cluster the moment the
apply lands. Do it deliberately, on its own, not as a side effect of another
change.

## Target topology

Three control plane nodes, brought up one at a time:

1. `cp1` — bootstraps etcd
2. `cp2` — joins
3. `cp3` — completes the quorum

Workloads run on the control plane (no `NoSchedule` taint, see below), so there
are no separate workers.

## Technical baseline

The schematic in `image.tf` carries these official extensions:

- `siderolabs/iscsi-tools` — Longhorn and other iSCSI-backed storage
- `siderolabs/nfs-utils` — NFS mounts
- `siderolabs/util-linux-tools` — `fstrim` and friends, wanted by Longhorn

They are listed in `var.system_extensions` and resolved against the factory for
`var.talos_version` at plan time. An extension that does not exist for that
version fails the plan rather than producing a schematic quietly missing it.

`patch.yaml` applies to every node:

- **NTP** — `at.pool.ntp.org`, via a `TimeSyncConfig` document
- **CNI** — none. Install Cilium after bootstrap; nodes stay `NotReady` until
  you do
- **kube-proxy** — disabled, for Cilium's kube-proxy replacement
- **Scheduling** — allowed on control planes
- **Metrics** — controller-manager, scheduler and etcd bind their metrics
  listeners to the LAN so Prometheus can scrape them

## Config document formats

The base config is generated against a 1.14 contract
(`var.machine_config_contract`). That contract emits the Kubernetes settings as
single-purpose documents — `KubeSchedulerConfig`, `KubeProxyConfig`,
`KubeNodeConfig`, `UnattendedInstallConfig` and more — and Talos rejects a
config that also sets the matching v1alpha1 field (*... is already set in
v1alpha1 config*). So the patches target the documents:

| Setting                         | Document                                       |
| ------------------------------- | ---------------------------------------------- |
| Install disk + installer image  | `UnattendedInstallConfig` (per node)           |
| Scheduling on control planes    | `KubeNodeConfig`, `taints: {$patch: delete}`   |
| Scheduler / controller-manager  | `KubeSchedulerConfig` / `KubeControllerManagerConfig` |
| No kube-proxy                   | `KubeProxyConfig`, `enabled: false`            |
| No CNI                          | `KubeFlannelCNIConfig`, `$patch: delete`       |
| containerd tweak                | `CRICustomizationConfig`                       |
| KubePrism on 7445               | generated `KubePrismConfig`, nothing to patch  |

Still v1alpha1, because nothing conflicts with them: `machine.network.interfaces`
(with the VIP), `cluster.etcd`, and `machine.disks`.

There is no document equivalent of `allowSchedulingOnControlPlanes`: the
generator always taints control-plane nodes `NoSchedule`, and the provider has
no option to stop it. Deleting the `taints` key is the fix. `taints: {}` does
not work, because an empty map merges into the generated one and changes
nothing.

Two more places where this bites, both handled:

- **Hostname.** The generated base config already contains a `HostnameConfig`
  document with `auto: stable`. Setting `machine.network.hostname` as well
  makes Talos 1.14 reject the configuration outright — *static hostname is
  already set in v1alpha1 config*. `config.tf` patches the document instead,
  and turns `auto` off in the same patch, because documents merge field by
  field and leaving `auto: stable` in place trips *auto and hostname cannot be
  set at the same time*.
- **Data disks.** `machine.disks` is deprecated in favour of
  `UserVolumeConfig`, and is kept anyway — see below.

### Migrating the data disk to `UserVolumeConfig`

`UserVolumeConfig` provisions a partition labelled `u-<name>`, mounted at
`/var/mnt/<name>`. That is **not** the layout `machine.disks` produced, so
switching in place reformats the disk and destroys whatever Longhorn has on
it. It is a data migration, not a config change:

1. Confirm Longhorn has healthy replicas of every volume on other nodes.
2. Cordon and drain the node, and let Longhorn rebuild elsewhere.
3. Drop `data_disk` for that node, apply, and wipe the disk
   (`talosctl -n <node> wipe disk <device>`).
4. Add the `UserVolumeConfig` document for the node, apply, and let Longhorn
   rebuild onto it.

Repeat per node. Until the provider can express the rest of the 1.14 document
set, there is little reason to rush it.

## Prerequisites

- `terraform` (>= 1.9 — `variables.tf` uses cross-variable validation)
- `talosctl`, `kubectl`, `helm`
- 1 to 3 bare-metal servers
- A free address on the node subnet reserved for the API VIP

## Step 1: Define your environment

```bash
cp terraform.tfvars.example terraform.tfvars
```

Start with `cp1` alone. Prefer `/dev/disk/by-id/...` for both disks, and keep
`interface_mac` lowercase — Talos compares it as a string, and an uppercase MAC
leaves the node with no `lan0`, no address and no route. `terraform validate`
catches that one, along with a VIP that collides with a node address, a reused
MAC, and an install disk pointed at the data disk.

## Step 2: Boot `cp1`

```bash
terraform init
terraform apply -target=talos_image_factory_schematic.this
terraform output -raw iso_url    # burn or mount this
terraform output -raw pxe_url    # or boot it over the network
```

Both URLs come from the schematic, so they always match the extensions and the
Talos version this stack is about to install.

## Step 3: Apply and bootstrap

```bash
terraform apply
```

This registers the schematic, generates the secrets and machine
configurations, applies them to each node, bootstraps etcd, waits for the
control plane to come up, and exports `talosconfig` and `kubeconfig`.

## Step 4: Verify access

```bash
terraform output -raw talosconfig > talosconfig
terraform output -raw kubeconfig > kubeconfig

talosctl --talosconfig ./talosconfig -n <cp1_ip> health
KUBECONFIG=./kubeconfig kubectl get nodes
```

Nodes stay `NotReady` until the CNI is installed.

## Step 5: Install Cilium (CNI)

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

`k8sServiceHost=localhost:7445` is KubePrism, enabled in `patch.yaml`.

## Step 6: Install Longhorn (storage)

```bash
KUBECONFIG=./kubeconfig kubectl create namespace longhorn-system
KUBECONFIG=./kubeconfig kubectl label namespace longhorn-system \
  pod-security.kubernetes.io/enforce=privileged --overwrite

helm repo add longhorn https://charts.longhorn.io
KUBECONFIG=./kubeconfig helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set defaultSettings.defaultDataPath=/var/mnt/longhorn \
  --set defaultSettings.defaultReplicaCount=3
```

## Step 7: Scale out

Add `cp2` and `cp3` to `terraform.tfvars`, boot them from the same ISO, and
apply. Terraform generates and applies their configuration and they join.

## Operations

### The health gate

`data.talos_cluster_health` sits between the bootstrap and the kubeconfig, so
the kubeconfig is only fetched once etcd and the API server are up. Kubernetes
checks are skipped — with `cni: none` they cannot pass until Cilium is
installed.

It reads on every plan, which means every plan wants the control plane
reachable. When a node is deliberately down:

```bash
terraform plan -var wait_for_cluster_health=false
```

### Upgrading Talos

`terraform apply` upgrades running nodes directly — `talos_machine.image` is
set to the same installer image baked into the `UnattendedInstallConfig`, so a
version bump changes both at once:

```bash
# 1. Bump the pin
#    talos_version in variables.tf (or terraform.tfvars)

# 2. Apply — resolves the new schematic/installer AND upgrades each node
terraform apply -parallelism=1
```

`-parallelism=1` is what keeps this safe: `talos_machine` has no staging
mode, so a node reboots as soon as its `apply` step runs. Parallelism 1 makes
that sequential across the `for_each`, one control-plane node at a time,
instead of risking all three at once. Watch health between nodes
(`talosctl --talosconfig ./talosconfig -n <node> health`) if you want to
abort before the next one starts.

The machine configuration *contract* is a separate pin,
`var.machine_config_contract` (1.14), and does not move with `talos_version`.
A Talos upgrade does not need it. A contract bump changes the shape of the
generated config — 1.14 is what moved the Kubernetes settings into documents —
so bump it only together with `patch.yaml` and `config.tf`, and render the
result (`talosctl validate --mode metal`) before applying.

### Upgrading Kubernetes

```bash
# kubernetes_version in variables.tf (or terraform.tfvars)
terraform apply
```

This one does act immediately: Terraform rewrites the control plane component
versions and Talos rolls them. One minor at a time, and check the Kubernetes
release notes first.

### Changing extensions

Edit `var.system_extensions`. `terraform plan` resolves the names against the
factory, produces a new schematic ID and a new installer image; an extension
that does not exist for `talos_version` fails the plan. Rolling it out to
running nodes is the `talosctl upgrade` procedure above — the installer image
is what carries extensions.

### Rotating nothing by accident

`talos_machine_secrets` holds the cluster CAs, the bootstrap token and the
encryption secrets. It is the one resource in this stack that must never be
replaced: replacing it is a new cluster. `talos_version` on that resource is a
plain in-place attribute and does not rotate anything.

## Tests

```bash
make test STACK=talos     # or: terraform test
```

`tests/validation.tftest.hcl` covers the node map and the cluster-level
values with `mock_provider`, so it needs no credentials and touches nothing.

This is also why `main.tf` uses data sources rather than the provider's
ephemeral resources: Terraform cannot mock ephemeral resource types, so the
first `ephemeral` block in this stack takes the whole suite down with it — the
same wall the `github` stack hit. The state already holds
`talos_machine_secrets`, so routing the rendered config around state would
remove a second copy of material that is in there regardless. Catching a
machine configuration bound for the wrong host is worth more. Worth revisiting
when Terraform can mock ephemerals.
