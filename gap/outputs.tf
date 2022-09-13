output "cluster_config" {
  value = local.cluster_config
}

output "vpc_config" {
  value = local.vpc_config
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC CIDR"
}

output "public_domain" {
  value       = local.domain_name
  description = "Public domain name"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "List of private subnet IDs"
}

output "private_route_table_ids" {
  value       = module.vpc.private_route_table_ids
  description = "List of private Route Table IDs"
}

output "natgw_ids" {
  value       = module.vpc.natgw_ids
  description = "List of Elastic IPs associated with NAT gateways"
}

output "utility_internal_hosted_zone" {
  value = aws_route53_zone.internal_domain.id
}

output "eks_admin_role" {
  value = module.eks_admin_role.iam_role_arn
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
