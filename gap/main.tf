module "vpc" {
  source = "../modules/vpc"

  name = "${local.project}-vpc-${local.environment}"
  cidr = local.vpc_config.vpc_cidr_block
  azs  = slice(data.aws_availability_zones.available.names, 0, local.vpc_config.vpc_availability_zones)

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  enable_dhcp_options    = true

  # Public subnets
  public_subnets               = local.vpc_config.vpc_public_subnet_cidr_blocks
  public_dedicated_network_acl = true

  # Application subnets
  private_subnets               = local.vpc_config.vpc_private_subnet_cidr_blocks
  private_subnet_suffix         = "private"
  private_dedicated_network_acl = true

  tags = local.tags 
}

# Internal Domain
resource "aws_route53_zone" "internal_domain" {
  name = local.internal_domain_name

  vpc {
    vpc_id = module.vpc.vpc_id
  }  

  lifecycle {
    ignore_changes = all
  }
}

# EKS cluster
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

data "aws_iam_policy_document" "eks_admin_policy" {
  statement {
    actions = [
      "eks:*"
    ]
    resources = [
      module.eks.cluster_iam_role_arn,
      "${module.eks.cluster_iam_role_arn}/*"
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"

      values = ["eks.amazonaws.com"]
    }
    resources = ["*"]    
  }   
}

resource "aws_iam_policy" "eks_admin_policy" {
  name        = "${local.cluster_config.cluster_name}-admin-${random_string.this.id}"
  path        = "/"
  description = "Admin Policy for the ${local.cluster_config.cluster_name} EKS cluster"
  policy = data.aws_iam_policy_document.eks_admin_policy.json
}

module "eks_admin_role" {
  source = "../modules/iam/iam-assumable-role"

  trusted_role_arns = local.cluster_config.eks_admins_arns

  create_role = true

  role_name         = "${local.cluster_config.cluster_name}-admin-${random_string.this.id}"
  role_requires_mfa = false

  custom_role_policy_arns = [aws_iam_policy.eks_admin_policy.arn]
}

module "vpc_cni_irsa" {
  source  = "../modules/iam/iam-role-for-service-accounts-eks"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv6   = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

module "eks" {
  source = "../modules/eks"

  cluster_name    = local.cluster_config.cluster_name
  cluster_version = local.cluster_config.cluster_version

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = local.cluster_config.eks_endpoint_public_access

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }  

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }  

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  # Managed Node Groups
  eks_managed_node_group_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  eks_managed_node_groups = local.cluster_config.eks_node_groups

  # aws-auth configmap
  manage_aws_auth_configmap = true

  enable_irsa = true

  # AWS Auth (kubernetes_config_map)
  aws_auth_roles = [
    {
      rolearn  = module.eks_admin_role.iam_role_arn
      username = "manager"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_users = [for s in local.cluster_config.eks_admins_arns : 
    {
      userarn  = s
      username = "eks-admin"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_accounts = [data.aws_caller_identity.current.account_id]

  tags = local.tags
}

# Cert Manager
module "cert_manager" {
  source = "../modules/cert_manager"

  depends_on = [
    module.eks
  ]

  cluster_name = local.cluster_config.cluster_name
  notifications_email = local.notifications_email

  tags = local.tags
}

# Ingress Controller
module "ingress_controller" {
  depends_on = [
    module.cert_manager
  ]
  source = "../modules/ingress_controller"

  cluster_name = local.cluster_config.cluster_name
  private_ingress = true
  # If private true then subnets must be passed. 
  private_subnets = join("\\,", module.vpc.private_subnets)

  tags = local.tags
}

module "web" {
  source = "../modules/gap_service"

  service_name = "gap-web"
  namespace =  "default"
  public_domain_hosted_zone = aws_route53_zone.internal_domain.id
  application_ingress_endpoint = module.ingress_controller.public_load_balancer_endpoint
  environment = local.environment
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_cluster_name = local.cluster_config.cluster_name
}

