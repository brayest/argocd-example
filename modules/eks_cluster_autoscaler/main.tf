data "aws_region" "current" {}

resource "random_string" "this" {
  length  = 4
  special = false
  upper   = false
}

data "aws_iam_policy_document" "eks_cluster_autoscaler" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes"
    ]
    resources = ["*"]
  } 
}

resource "aws_iam_policy" "eks_cluster_autoscaler" {
  name        = "${var.cluster_name}-eks-cluster-autoscaler-policy-${random_string.this.id}"
  path        = "/"
  description = "Admin Policy for the ${var.cluster_name} EKS cluster"
  policy = data.aws_iam_policy_document.eks_cluster_autoscaler.json
}


module "eks_cluster_autoscaler_role" {
  source = "../iam/iam-assumable-role-with-oidc"

  create_role = true

  role_name = "${var.cluster_name}-eks-cluster-autoscaler-role-${random_string.this.id}"

  tags = var.tags

  provider_url  = var.eks_oidc_provier
  provider_urls = [var.eks_oidc_provier]

  role_policy_arns = [
    aws_iam_policy.eks_cluster_autoscaler.arn
  ]

  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler"]
}

resource "helm_release" "cluster_autoscaler" {
  name  = "${var.cluster_name}-cluster-autoscaler"
  chart = "${path.module}/autoscaler"

  namespace = "kube-system"

  set {
      name = "AutoscalerRoleArn"
      value = module.eks_cluster_autoscaler_role.iam_role_arn
  }

  set {
      name = "ClusterName"
      value = var.cluster_name
  }

  set {
      name = "ClusterVersion"
      value = var.cluster_version
  }  
}
