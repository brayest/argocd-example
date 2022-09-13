variable "cluster_name" {
  type = string
}
variable "tags" {
  description = "Tags to be applied to the resource"
  default     = {}
  type        = map(any)
}
variable "eks_oidc_provier" {
  type = string
}
variable "cluster_version" {
  type = string
  default = "1.21"
}