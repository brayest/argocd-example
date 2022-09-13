# AWS infrastructure
resource "aws_ecr_repository" "this" {
  name                 = var.service_name
  image_tag_mutability = "MUTABLE"
  
  encryption_configuration {
      encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_route53_record" "this" {
  zone_id = var.public_domain_hosted_zone
  name    = var.service_name
  type    = "CNAME"
  ttl     = "300"
  records = [var.application_ingress_endpoint]
}

# Vault default Kubernetes integration
resource "kubernetes_service_account" "this" {
  metadata {
    name = "vault-auth-${var.environment}-${var.service_name}"
    namespace = var.namespace != null ? var.namespace : var.service_name    
  }
}

data "kubernetes_secret" "this" {
  metadata {
    name = kubernetes_service_account.this.default_secret_name
    namespace = kubernetes_service_account.this.metadata[0].namespace
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = "k8-role-${var.eks_cluster_name}-${var.service_name}-tokenreview-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata[0].name
    namespace = kubernetes_service_account.this.metadata[0].namespace
  }  
}
