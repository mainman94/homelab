# Talos Bare-Metal Bootstrap

Dieses Verzeichnis ist auf einen Terraform-first-Workflow für Talos auf Bare Metal ausgelegt.

Enthalten sind:

- das Factory-Schematic in [schematic.yaml](/Users/philippmatthiashauptmann/work/talos/schematic.yaml)
- der gemeinsame Cluster-Patch in [patch.yaml](/Users/philippmatthiashauptmann/work/talos/patch.yaml)
- die Terraform-Konfiguration in [terraform/main.tf](/Users/philippmatthiashauptmann/work/talos/terraform/main.tf)

Die vorhandenen [controlplane.yaml](/Users/philippmatthiashauptmann/work/talos/controlplane.yaml) und [worker.yaml](/Users/philippmatthiashauptmann/work/talos/worker.yaml) sind alte generierte Artefakte und nicht Teil des empfohlenen Workflows.

## Zielbild

Ziel ist ein Bare-Metal-Cluster, der so aufgebaut wird:

1. zuerst nur `cp1`
2. danach `cp2`
3. danach `cp3`

Die Zieltopologie ist also:

- `cp1`: control plane
- `cp2`: control plane
- `cp3`: control plane

So bekommst du zuerst einen lauffähigen Cluster und erhöhst danach auf ein 3-Node-Control-Plane-Setup mit etcd-Quorum und API-HA.

## Technische Basis

Das Schematic aus [schematic.yaml](/Users/philippmatthiashauptmann/work/talos/schematic.yaml) enthält diese Extensions:

- `siderolabs/iscsi-tools`
- `siderolabs/nfs-utils`
- `siderolabs/util-linux-tools`

Der gemeinsame Patch in [patch.yaml](/Users/philippmatthiashauptmann/work/talos/patch.yaml) setzt:

- kein eingebautes CNI
- `kube-proxy` deaktiviert

Das bedeutet: nach dem Bootstrap musst du direkt ein CNI mit kube-proxy-Replacement installieren, typischerweise Cilium.

## Voraussetzungen

Du brauchst:

- `terraform`
- `talosctl`
- `kubectl`
- 1 bis 3 Bare-Metal-Server
- ein Netz mit festen IPs
- idealerweise eine API-VIP, z. B. `192.168.0.10`

Beispiel:

- `cp1`: `192.168.0.11`
- `cp2`: `192.168.0.12`
- `cp3`: `192.168.0.13`
- `cluster endpoint / VIP`: `192.168.0.10`
- `gateway`: `192.168.0.2`

## Factory-ID aus dem Schematic

Die Terraform-Konfiguration verwendet den Talos-Provider `0.10.x` und erzeugt die Factory-ID direkt aus [schematic.yaml](/Users/philippmatthiashauptmann/work/talos/schematic.yaml) über `talos_image_factory_schematic`.

Du musst die `schematic_id` daher nicht manuell in Terraform pflegen.

Wenn du die ID trotzdem vorab prüfen willst, hast du zwei Wege:

1. in der Talos Image Factory im Browser
2. per API-Aufruf mit `curl`

Beispiel:

```bash
curl -X POST \
  -H "Content-Type: application/yaml" \
  --data-binary @schematic.yaml \
  https://factory.talos.dev/schematics
```

Die Antwort enthält die erzeugte Schematic-ID.

## Terraform-Struktur

Die eigentliche Cluster-Verwaltung liegt in:

- [terraform/versions.tf](/Users/philippmatthiashauptmann/work/talos/terraform/versions.tf)
- [terraform/variables.tf](/Users/philippmatthiashauptmann/work/talos/terraform/variables.tf)
- [terraform/main.tf](/Users/philippmatthiashauptmann/work/talos/terraform/main.tf)
- [terraform/outputs.tf](/Users/philippmatthiashauptmann/work/talos/terraform/outputs.tf)
- [terraform/terraform.tfvars.example](/Users/philippmatthiashauptmann/work/talos/terraform/terraform.tfvars.example)

Die Konfiguration macht Folgendes:

- registriert das Schematic aus [schematic.yaml](/Users/philippmatthiashauptmann/work/talos/schematic.yaml)
- erzeugt Cluster-Secrets
- generiert daraus die Talos-Machine-Configs
- patcht pro Node Netzwerk sowie Install-/Data-Disks
- spielt die Konfiguration auf die Nodes
- bootstrapped `cp1`
- zieht `talosconfig` und `kubeconfig` als Terraform-Outputs

## Wichtige Variablen

Die wichtigsten Eingaben stehen in [terraform/terraform.tfvars.example](/Users/philippmatthiashauptmann/work/talos/terraform/terraform.tfvars.example):

- `cluster_endpoint`
- `cluster_vip`
- `gateway`
- `talos_version`
- `kubernetes_version`
- `controlplane_nodes`

`kubernetes_version` kommt nicht automatisch "von Talos", sondern wird in [terraform/main.tf](/Users/philippmatthiashauptmann/work/talos/terraform/main.tf) bewusst an `talos_machine_configuration` übergeben. Das ist sinnvoll, weil die Zielversion damit explizit und reproduzierbar ist.

## Schritt 1: `cp1` definieren

Erstelle zuerst deine lokale Arbeitsdatei:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Trage zunächst nur `cp1` ein:

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

Wichtig:

- `install_disk` muss zum echten Bare-Metal-Host passen
- `interface` muss der echte NIC-Name sein
- `cluster_endpoint` sollte auf deine VIP zeigen
- `node_name` ist optional und setzt den Talos/Kubernetes-Node-Namen (Hostname)
- `data_disk` ist optional pro Node und wird für Longhorn-Daten genutzt

Formatierung/Provisionierung der `data_disk`:

- Talos provisioniert die zusätzliche Disk beim Anwenden der Machine-Config (falls noch nicht passend provisioniert).
- Dabei wird die Partition angelegt und auf den angegebenen Mountpoint eingehängt.
- Für Stabilität besser `/dev/disk/by-id/...` statt `/dev/sdX` verwenden.

## Schritt 2: `cp1` mit dem Factory-Image booten

Boote nur `cp1` mit dem Talos-Factory-ISO oder per PXE.

Das Boot-Image muss aus dem Schematic in [schematic.yaml](/Users/philippmatthiashauptmann/work/talos/schematic.yaml) gebaut sein, damit die Extensions im Installer enthalten sind.

Wenn `cp1` im Maintenance Mode erreichbar ist, kannst du das optional prüfen:

```bash
talosctl -n 192.168.0.11 version
```

## Schritt 3: Terraform initialisieren und `cp1` bootstrappen

```bash
cd terraform
terraform init
terraform apply
```

Dabei passiert:

- die Factory-ID wird aus dem Schematic erzeugt
- das Installer-Image wird daraus abgeleitet
- Talos-Secrets werden erzeugt
- die Maschinenkonfiguration für `cp1` wird gebaut
- die Konfiguration wird auf `cp1` angewendet
- `cp1` wird gebootstrapped
- `talosconfig` und `kubeconfig` werden als Outputs bereitgestellt

## Schritt 4: Zugriff prüfen

Talosconfig aus Terraform holen:

```bash
terraform output -raw talosconfig > talosconfig
```

Kubeconfig aus Terraform holen:

```bash
terraform output -raw kubeconfig > kubeconfig
```

Cluster prüfen:

```bash
talosctl --talosconfig ./talosconfig -n 192.168.0.11 health
KUBECONFIG=./kubeconfig kubectl get nodes
```

Direkt nach dem Bootstrap ist der Node ohne CNI noch nicht vollständig `Ready`. Das ist in diesem Setup normal.

## Schritt 5: CNI installieren

Weil in [patch.yaml](/Users/philippmatthiashauptmann/work/talos/patch.yaml) `cni: none` und `proxy.disabled: true` gesetzt sind, installierst du danach direkt ein CNI mit kube-proxy-Replacement.

Typischerweise Cilium:

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update
helm template \
    cilium \
    cilium/cilium \
    --version 1.19.2 \
    --namespace kube-system \
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

Danach erneut prüfen:

```bash
KUBECONFIG=./kubeconfig kubectl get nodes
KUBECONFIG=./kubeconfig kubectl -n kube-system get pods
```

## Schritt 6: Longhorn installieren

Für Longhorn den Namespace zuerst selbst anlegen und auf `privileged` setzen:

```bash
KUBECONFIG=./kubeconfig kubectl create namespace longhorn-system
KUBECONFIG=./kubeconfig kubectl label namespace longhorn-system \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged \
  --overwrite
```

Dann Longhorn per Helm installieren (für `cp1`-only mit einer Replica):

```bash
KUBECONFIG=./kubeconfig helm repo add longhorn https://charts.longhorn.io
KUBECONFIG=./kubeconfig helm repo update
KUBECONFIG=./kubeconfig helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set defaultSettings.defaultDataPath=/var/mnt/longhorn \
  --set defaultSettings.defaultReplicaCount=1
```

Status prüfen:

```bash
KUBECONFIG=./kubeconfig kubectl -n longhorn-system get pods
KUBECONFIG=./kubeconfig kubectl get sc
```

## Schritt 7: Migration-Smoketest auf `cp1` (optional, empfohlen)

Bevor du `cp2`/`cp3` hinzufügst, kannst du auf einem Single-Node-Cluster bereits Workloads und Migrationspfade testen.

Falls Workloads wegen Control-Plane-Taint nicht schedulen, temporär für den Test entfernen:

```bash
KUBECONFIG=./kubeconfig kubectl taint nodes cp1 node-role.kubernetes.io/control-plane-
```

Beispiel-Smoke-Test:

```bash
KUBECONFIG=./kubeconfig kubectl create ns migration-smoke
KUBECONFIG=./kubeconfig kubectl -n migration-smoke create deploy echo --image=nginx:stable
KUBECONFIG=./kubeconfig kubectl -n migration-smoke expose deploy echo --port=80 --type=ClusterIP
KUBECONFIG=./kubeconfig kubectl -n migration-smoke rollout status deploy/echo
KUBECONFIG=./kubeconfig kubectl -n migration-smoke get pods,svc,endpoints
```

Nach dem Test wieder aufräumen:

```bash
KUBECONFIG=./kubeconfig kubectl delete ns migration-smoke
```

## Schritt 8: `cp2` hinzufügen

Wenn `cp1` stabil läuft, ergänze `cp2` in [terraform/terraform.tfvars.example](/Users/philippmatthiashauptmann/work/talos/terraform/terraform.tfvars.example) bzw. deiner lokalen `terraform.tfvars`:

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

Boote `cp2` mit demselben Factory-Image und führe dann erneut aus:

```bash
terraform apply
```

Terraform erzeugt dann nur die zusätzliche Konfiguration für `cp2` und fügt den Node zum bestehenden Cluster hinzu.

## Schritt 9: `cp3` hinzufügen

Danach identisch für `cp3`:

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

Dann:

```bash
terraform apply
```

## Betrieb

Ab diesem Punkt solltest du Konfigurationsänderungen über Terraform pflegen und nicht manuell auf den Nodes.

Typische Änderungen:

- neue Control-Plane-Nodes ergänzen
- Disk- oder Netzwerkparameter anpassen
- `talos_version` erhöhen
- `kubernetes_version` bewusst anheben
- Schematic erweitern und daraus ein neues Installer-Image ableiten

`talosctl` bleibt für Debugging sinnvoll, aber der Sollzustand sollte in Terraform liegen.
