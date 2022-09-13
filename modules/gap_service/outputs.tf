output "service_account_name" {
  value = kubernetes_service_account.this.metadata[0].name
}

output "ecr_repository" {
  value = aws_ecr_repository.this.repository_url
}