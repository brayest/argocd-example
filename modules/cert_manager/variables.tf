variable "cluster_name" {
  type = string
  default = "Cluster"
}
variable "tags" {
  description = "Tags to be applied to the resource"
  default     = {}
  type        = map(any)
}

variable "notifications_email" {
  type = string
}