# Kubeconfig for talos_machine's drain_on_upgrade.
#
# Built offline from the Kubernetes CA in talos_machine_secrets, so it does
# not depend on the cluster being bootstrapped. talos_cluster_kubeconfig reads
# from a running node and sits after talos_machine_bootstrap, which makes it
# unusable as an input to talos_machine. The provider's ephemeral
# talos_cluster_kubeconfig would also work, but it cannot be mocked and would
# stop tests/ from running (see main.tf).
#
# The CA key is already in state through talos_machine_secrets, so the admin
# certificate below adds no new secret material to it.

locals {
  k8s_ca = talos_machine_secrets.this.machine_secrets.certs.k8s
}

resource "tls_private_key" "drain" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "drain" {
  private_key_pem = tls_private_key.drain.private_key_pem

  subject {
    common_name  = "terraform-talos-drain"
    organization = "system:masters"
  }
}

# Replaced on the first apply inside the renewal window, so the certificate
# never expires as long as the stack is applied at least once a month.
resource "tls_locally_signed_cert" "drain" {
  cert_request_pem   = tls_cert_request.drain.cert_request_pem
  ca_private_key_pem = base64decode(local.k8s_ca.key)
  ca_cert_pem        = base64decode(local.k8s_ca.cert)

  validity_period_hours = 24 * 365
  early_renewal_hours   = 24 * 30

  allowed_uses = [
    "digital_signature",
    "client_auth",
  ]
}

locals {
  drain_kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "drain"
    clusters = [{
      name = var.cluster_name
      cluster = {
        server                     = var.cluster_endpoint
        certificate-authority-data = local.k8s_ca.cert
      }
    }]
    users = [{
      name = "terraform-talos-drain"
      user = {
        client-certificate-data = base64encode(tls_locally_signed_cert.drain.cert_pem)
        client-key-data         = base64encode(tls_private_key.drain.private_key_pem)
      }
    }]
    contexts = [{
      name = "drain"
      context = {
        cluster = var.cluster_name
        user    = "terraform-talos-drain"
      }
    }]
  })
}
