# General Config
region                  = "us-east-1"
project                 = "gap"
environment             = "dev"
domain_name             = "argocd-example.com"
internal_domain_name    = "gap.int"
public_key_name         = "gap_infrastructure"
dev_accout_id           = "159783617695"

# VPC config
vpc_cidr_block          = "10.100.0.0/16"
azs_count               = 3
number_subnets          = 3
vpc_offset              = 4

# Applications 
btp_applications = [
  "btp-web", 
]

# EKS node config 
cluster_version            = "1.22"
eks_endpoint_public_access =  true
eks_admins_arns = [
    "arn:aws:iam::020663747723:user/blemus",
  ]
eks_node_groups ={
    default = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.small"]
      ami_type = "AL2_x86_64"
      capacity_type  = "SPOT"
    }  

    nginx = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types  = ["t3.small"]
      capacity_type   = "ON_DEMAND"
      ami_type = "AL2_x86_64"
      labels = {
        nodegroup-type = "nginx"
      }       
    }             
  }
