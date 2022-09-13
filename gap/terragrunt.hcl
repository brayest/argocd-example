locals {
  indentifier   = "gap" 
  aws_region    = "us-east-1"  
  profile       = "gap"

  backend_bucket = "${local.indentifier}-terraform-state-${local.aws_region}-${get_aws_account_id()}"
  dynamodb_table = "${local.indentifier}-lock-table-${local.aws_region}-${get_aws_account_id()}"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = local.backend_bucket
    dynamodb_table = local.dynamodb_table
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    profile        = local.profile
  }
}
