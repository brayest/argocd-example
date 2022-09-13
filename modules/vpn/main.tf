resource "random_string" "this" {
  length  = 4
  special = false
  upper   = false
}

# resource "null_resource" "git_clone_easy_rsa" {
#   provisioner "local-exec" {
#     command = "/usr/bin/git clone https://github.com/OpenVPN/easy-rsa.git easy-rsa"
#   } 
# }

# # resource "null_resource" "remove_dummy_pki" {
# #   depends_on = [
# #     null_resource.git_clone_easy_rsa
# #   ]

# #   provisioner "local-exec" {
# #     command = "rm -R pki"
# #   }
# # }

# resource "null_resource" "initiate_pki" {
#   depends_on = [
#     null_resource.git_clone_easy_rsa
#   ]

#   provisioner "local-exec" {
#     command = "./easy-rsa/easyrsa3/easyrsa init-pki"
#   }
# }

# resource "null_resource" "create_certificate_domain" {
#   depends_on = [
#     null_resource.initiate_pki
#   ]

#   provisioner "local-exec" {
#     command = "./easy-rsa/easyrsa3/easyrsa --batch build-ca nopass"
#   }
# }

# resource "null_resource" "create_certificate" {
#   depends_on = [
#     null_resource.create_certificate_domain
#   ]  
#   provisioner "local-exec" {
#     command = "./easy-rsa/easyrsa3/easyrsa build-server-full nopass"
#   }
# }

module "vpn_bucket" {
  source = "../s3"

  bucket = "${var.project}-vpn-pki-${var.environment}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-${random_string.this.id}"
  acl    = "private"
  force_destroy = true

  versioning = "Enabled"
}

resource "null_resource" "upload_pki" {
  depends_on = [
    module.vpn_bucket
  ]  
  provisioner "local-exec" {
    command = "aws s3 cp pki/ s3://${module.vpn_bucket.s3_bucket_id}/pki --region ${data.aws_region.current.name} --recursive"
  }
}

resource "aws_acm_certificate" "cert" {
  private_key      = trimspace(templatefile("pki/private/server.key", {}))
  certificate_body = trimspace(templatefile("pki/issued/server.crt", {}))
  certificate_chain = trimspace(templatefile("pki/ca.crt", {}))
}

resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
  description            = "${var.project}-vpn-pki-${var.environment}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-${random_string.this.id}"
  server_certificate_arn = aws_acm_certificate.cert.arn
  client_cidr_block      = "10.200.0.0/16"
  transport_protocol     = "tcp"
  split_tunnel           = true

  dns_servers = [ for k in var.associated_subnet_cidr : "${replace(k, "0/16", "2")}"]
  
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.cert.arn
  }

  connection_log_options {
    enabled               = false
  }
}

resource "aws_ec2_client_vpn_network_association" "subnet_association" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = var.association_subnet_id
}

resource "aws_ec2_client_vpn_authorization_rule" "ingress_rule" {
  count = length(var.associated_subnet_cidr)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  target_network_cidr    = var.associated_subnet_cidr[count.index]
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_route" "utility_vpn_route" {
  count = length(var.route_subnet_cidr)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  destination_cidr_block = var.route_subnet_cidr[count.index]
  target_vpc_subnet_id   = var.association_subnet_id
}
