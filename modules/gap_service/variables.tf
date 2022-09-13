variable "service_name" {
  type = string
}

variable "public_domain_hosted_zone" {
  type = string 
}

variable "application_ingress_endpoint" {
  type = string
}

variable "environment" {
  type = string
  default = "dev"
}

variable "eks_cluster_name" {
  type = string
}

variable "eks_cluster_endpoint" {
  type = string
}

variable "namespace" {
  type = string
  default = null
}
 
variable "extra_vault_policies" {
  type = list(string)
  default = []
}