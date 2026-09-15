# Cluster metrics dashboard for eggenberg-talos-cluster-1, fed by the
# splunk-otel-collector agent/cluster-receiver deployment. Previously this
# lived only as a manually-created dashboard in the Splunk O11y UI, which is
# why it vanished (and any link to it broke — "No dashboard found with
# import ID: ..."). Declaring it here means it survives and is reviewable.
resource "signalfx_dashboard_group" "homelab" {
  name        = "eggenberg-homelab"
  description = "Dashboards for the eggenberg-talos-cluster-1 homelab, managed via Terraform"
}

resource "signalfx_time_chart" "node_cpu_utilization" {
  name = "Node CPU utilization"

  program_text = <<-EOF
    A = data('cpu.utilization', filter=filter('k8s.cluster.name', '${var.cluster_name}')).mean(by=['host'])
    A.publish(label='CPU utilization')
  EOF

  plot_type = "LineChart"
}

resource "signalfx_time_chart" "node_memory_utilization" {
  name = "Node memory utilization"

  program_text = <<-EOF
    A = data('memory.utilization', filter=filter('k8s.cluster.name', '${var.cluster_name}')).mean(by=['host'])
    A.publish(label='Memory utilization')
  EOF

  plot_type = "LineChart"
}

resource "signalfx_time_chart" "pod_count" {
  name = "Running pods"

  program_text = <<-EOF
    A = data('k8s.pod.phase', filter=filter('k8s.cluster.name', '${var.cluster_name}') and filter('phase', 'Running')).count()
    A.publish(label='Running pods')
  EOF

  plot_type = "LineChart"
}

resource "signalfx_dashboard" "cluster_overview" {
  name            = "Cluster overview"
  dashboard_group = signalfx_dashboard_group.homelab.id
  time_range      = "-1h"

  chart {
    chart_id = signalfx_time_chart.node_cpu_utilization.id
    row      = 0
    column   = 0
    width    = 6
    height   = 4
  }

  chart {
    chart_id = signalfx_time_chart.node_memory_utilization.id
    row      = 0
    column   = 6
    width    = 6
    height   = 4
  }

  chart {
    chart_id = signalfx_time_chart.pod_count.id
    row      = 4
    column   = 0
    width    = 6
    height   = 4
  }
}
