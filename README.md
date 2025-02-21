
```mermaid
architecture-beta
  group api_gateway[API Gateway]
  
  service vpc_link[VPC Link] in api_gateway
  service lambda_function[Lambda Function] in api_gateway
  service dynamodb[DynamoDB] in api_gateway

  api_gateway --> vpc_link
  vpc_link --> lambda_function
  lambda_function --> dynamodb

```





# Requirements



* GIT
* Terraform
* Terragrunt
* helm
* docker
* BASH
