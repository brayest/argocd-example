variable "domain_name" {
  type = string
}
variable "tags" {
  description = "Tags to be applied to the resource"
  default     = {}
  type        = map(any)
}
variable "project" {
  type    = string
  default = "bpt"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "association_subnet_id" {
  type = string
}
variable "associated_subnet_cidr" {
  type = list(string)
}

variable "route_subnet_cidr" {
  type = list(string)
}