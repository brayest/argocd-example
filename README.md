```mermaid
%%{init: {"theme": "base"}}%%
architecture
    %% Define the VPC group
    group vpc["VPC"]

    %% Define the API Gateway outside the VPC
    service api_gateway["API Gateway"]

    %% Define the VPC Link within the VPC
    service vpc_link["VPC Link"] in vpc

    %% Define the Network Load Balancer within the VPC
    service nlb["Network Load Balancer"] in vpc

    %% Define the backend service (e.g., ECS or an internal service) within the VPC
    service backend_service["Backend Service"] in vpc

    %% Define connections
    api_gateway --> vpc_link
    vpc_link --> nlb
    nlb --> backend_service
```