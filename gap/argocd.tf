resource "helm_release" "argocd" {
  name  = "${local.project}-argocd"
  chart = "${path.module}/applications/argo-cd"

  namespace = "argocd"
  create_namespace = true

  set {
    name = "server.ingress.enabled"
    value = true
  }

  set {
    name = "server.ingress.hosts[0]"
    value = "argocd.${local.internal_domain_name}"
  }  
}
