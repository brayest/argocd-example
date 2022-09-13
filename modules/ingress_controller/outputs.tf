output "public_load_balancer_endpoint" {
  value = data.kubernetes_service.public_ingress_controller_service.status.0.load_balancer.0.ingress.0.hostname  
}

output "internal_load_balancer_endpoint" {
  value = data.kubernetes_service.private_ingress_controller_service.status.0.load_balancer.0.ingress.0.hostname
}
