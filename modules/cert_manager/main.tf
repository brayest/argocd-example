resource "helm_release" "cert_manager" {
  name  = "${var.cluster_name}-cert-manager"
  chart = "${path.module}/cert-manager"

  namespace = "cert-manager"
  create_namespace = true

  set {
    name = "installCRDs"
    value = true
  }
}

resource "helm_release" "cluster_issuer" {
  name  = "${var.cluster_name}-cluster-issuer"
  chart = "${path.module}/cluster_issuer"

  namespace = "cert-manager"
  create_namespace = true

  set {
    name = "ClusterName"
    value = var.cluster_name
  }

  set {
    name = "NotificationsEmail"
    value = var.notifications_email
  }

  depends_on = [
    helm_release.cert_manager
  ]
}


