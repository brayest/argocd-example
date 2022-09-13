data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

resource "random_string" "this" {
  length  = 4
  special = false
  upper   = false
}

locals {
  cloud_account_id = data.aws_caller_identity.current.account_id
  region           = data.aws_region.current.name
  project          = var.project
  environment      = var.environment
  domain_name      = var.domain_name
  cluster_name     = "${var.project}-${var.environment}"

  public_key_name  = var.public_key_name

  internal_domain_name = var.internal_domain_name

  notifications_email = "blemus@wearegap.com"

  tags             = {
    Project = local.project
    Environment = var.environment
    Terraform = "managed"
  }

  account_config = {
    project	                        = local.project
    cloud_account_id                = data.aws_caller_identity.current.account_id
    environment                     = var.environment
    cluster_name                    = local.cluster_name
  }

  cidrs             = chunklist(cidrsubnets(var.vpc_cidr_block, [for i in range(var.azs_count * var.number_subnets) : var.vpc_offset]...), var.azs_count)
  public_cidrs      = local.cidrs[0]
  private_cidrs     = local.cidrs[1]     
  data_cidrs        = local.cidrs[2]     

  vpc_config = {
    vpc_name                       = "${var.project}-${var.environment}"
    vpc_availability_zones         = var.azs_count
    vpc_cidr_block                 = var.vpc_cidr_block
    vpc_public_subnet_cidr_blocks  = local.public_cidrs
    vpc_private_subnet_cidr_blocks = local.private_cidrs
    vpc_data_subnet_cidr_blocks    = local.data_cidrs
  }

  cluster_config = {
    region                               = local.region
    project                              = local.project
    environment                          = local.environment
    cluster_name                         = local.cluster_name
    cluster_version                      = var.cluster_version
    eks_endpoint_public_access           = var.eks_endpoint_public_access
    eks_node_groups                      = var.eks_node_groups
    eks_admins_arns                      = var.eks_admins_arns
  }
}
