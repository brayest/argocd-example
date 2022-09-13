variable "region" {
  type    = string
  default = "us-east-1"
}
variable "project" {
  type    = string
  default = "gap"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "cluster_version" {
  type    = string
  default = "1.22"
}
variable "public_key_name" {
  type    = string
  default = "gap_infrastructure"
}
variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default = false
}

variable "vpc_cidr_block" {
  type = string
  default = "10.100.0.0/16"
}

variable "azs_count" {
  type = number
  default = 3
}

variable "number_subnets" {
  type = number
  default = 3
  
}

variable vpc_offset {
        description     = "Denotes the number of address locations added to a base address in order to get to a specific absolute address, Usually the 8-bit byte"
        type            = number
        default         = "4"
}
variable "eks_endpoint_public_access" {
  type = bool
  default = true
}
variable "domain_name" {
  type = string
  default = "insurdata.vision"
}

variable "eks_node_groups" {
  type = any
  default = {
    default = {
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 0

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      ec2_ssh_key    = "btp_infrastructure"
    }  
  }
}

variable "eks_admins_arns" {
  type = list(string)
  default = []
}

variable "internal_domain_name" {
  type = string
  default = "gap.int"
}

variable "btp_applications" {
  type = list(string)
  default = ["gap-web"]
}

variable "dev_accout_id" {
  type = string
  default = "159783617695"
}