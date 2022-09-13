resource "helm_release" "ingress_controller" {

  name  = "${var.cluster_name}-ic"
  chart = "${path.module}/nginx-ingress"

  values = [
      "${file("${path.module}/nginx-ingress/values.yaml")}"
  ]   

  namespace = "nginx-ingress"
  create_namespace = true

  set {
    name = "controller.service.internal.enabled"
    value = var.private_ingress
  }

  set {
    name = "controller.service.internal.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-subnets"
    value = var.private_subnets
  }
}

data "kubernetes_service" "public_ingress_controller_service" { 
  depends_on = [
    helm_release.ingress_controller
  ]
  metadata {
    name = "${var.cluster_name}-ic-ingress-nginx-controller"
    namespace = "nginx-ingress"
  }
}

data "kubernetes_service" "private_ingress_controller_service" {
  depends_on = [
    helm_release.ingress_controller
  ]
    
  metadata {
    name = "${var.cluster_name}-ic-ingress-nginx-controller-internal"
    namespace = "nginx-ingress"
  }
}


