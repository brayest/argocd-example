```mermaid
architecture-beta
    %% Define the VPC group
    group vpc(cloud)[VPC]

    %% Define API Gateway (External)
    service api_gateway(internet)[API Gateway]

    %% Define VPC Link inside VPC
    service vpc_link(cloud)[VPC Link] in vpc

    %% Define Network Load Balancer inside VPC
    service nlb(server)[Network Load Balancer] in vpc

    %% Define Backend Services inside VPC
    service health_service(server)["Health Service"] in vpc
    service autopay_service(server)["Autopay Service"] in vpc
    service contact_service(server)["Contact Service"] in vpc

    %% Define connections
    api_gateway:R --> L:vpc_link
    vpc_link:R --> L:nlb
    nlb:R --> L:health_service
    nlb:R --> L:autopay_service
    nlb:R --> L:contact_service
```