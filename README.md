# Vikunja self hosted on AWS: Isolated Scalable Three Tier AWS ECS Project, with Blue/Green, CI/CD deployment, built with IaC - Terraform.
## This is a three tier based project for Vikunja application, that uses AWS S3 as the Frontend, and AWS ECS Fragate as the Backend. This project supports Blue/Green deployment with auto-scalablity that uses continues integration/continues delivery (CICD). This infrastructure is fully built in (Iac) using Terraform.
### Architecture
![Architecture](/Vikunja%20Architecture.png)
### Overview
[Vikunja](https://vikunja.io/) is an open source, self hostable application, used to add To Do tasks and orgranized one's projects. Vikunja software is isolated into a Frontend and Backend images. This is an AWS architecture that deploys Vikunja application on ECS as a backend and S3 as a frontend. The Backend uses a Network load balancer as an API endpoint and for scalbility, while S3 website is connected to a CloudFront distribution for CDN, and TLS support. This Vikunja application uses RDS MySQL instance database, and uses codepipeline to deliver a CI/CD automation using codebuild and codedeploy-ecs-blue/green deployment.
### Steps & Resources
The steps & resources were used are the following:
1. VPC:
   1. Create a VPC with two subnets; for the ECS scalability and the Load balancer - and another two subnets; for RDS
   2. Associate the four subnets to route table that routes to the internet gateway - RDS subnets can be restricted for certain IPs using ACL rules, or they can be kept as private subnets for internal connection only, and then connect the ECS task definition to the database using IAM policy.
   3. Create Security groups for the ECS appliaction, RDS MySQL instance, and load balancer
2. S3:
   1. Create S3 bucket for the frontend application, it will be used as a static website. The Frontend files will be uploaded to the bucket manually - uploading them using Terrafrom as S3_objet resource files sets their content-type to `binary/octet-stream`, Which will make the S3 website not function as expected and download the index.html file instead of viewing it as web page. 

   I tried changing the content-type of each file according to its extension but I still had errors when browsing the website. For this I hashed the `s3_object` resource and uploaded the files manually through the S3 console which automatically sets the correct content-type for each file.
   2. Create another S3 bucket to store artifacts of codebuild (optional).
3. ECR: 
   1. For the backend image, either use Vikunja's docker image directly, but pulling images from dockerhub is limited without user login. An altetnative solution is to re-tag the vikunja image and push it to an ECR registry, then use it repatedly in codedeploy appspec.yml and ECS task definition. This can be done by creating a seperate ECR resource, and then updating the terraform template after uploading the image - update the image variable in the variables.tf file.

   2. CodeBuild's buildspec.yml file is configured to use the ecr image uploaded to the ECR repository. It can be used to pull the image from vikunja's registry, tag it and push it to the ECR registry if required.

4. Network load balancer:
   1. By default, vikunja uses port 3456, so I used a network load balancer to forward the requests to teh backend. You may change the default port to 80 or 443 using vikunja's environment variables, then use Application Load balancer if required.
   2. The Network load balacner has two target groups which will be used by codeDeploy as a Blue/Green environments and adjust between them during deployment. By default, the listener is set to forward requests to the blue target group.

3. RDS:
   Created RDS instance that uses MySQL Engine. It uses security group that allows port 3306 and uses two subnet groups - minimum allowed.

4. ECS:
    1. Cluster
       1. ECS uses fargate cluster environment, which has logs enabled with cloudwatch logs. 
    
    2. Task definition
       1. The Task definition uses the vikunja's application environment variables and the RDS credentials as secret variables - that are defined using SSM.
       2. It's assigned to an execution role that uses `AmazonECSTaskExecutionRolePolicy` - which allows writing logs and using ECR image. RDS access - if not using public access - and SSM access (to access SSM parameters).
   
    3. Service:
       1. The service is configured to use the network load balancer, and autoscale from 1 - 4 tasks - using '**app autoscaing target**' & '**app autoscaling policy**' Terraform resources. It's also configured to use blue/green deployment by using `CODE_DEPLOY` attribute, that is defined using the **CodeDeploy** resource.

5. CodeDeploy:
   1. An Application created and configured, it uses Blue Green and set to use the ECS cluster and service, as it also uses both of the load balancer's blue/green environment target groups.

   2. A role was created and set to use by codedeploy, it allows configuring AWS ECS, using the AWS S3 artifacts bucket, that will have the appspec.yml stored by CodeBuild. - Typically this role policy is used for multiple resources, that is why it allows extra actions.

6. CodeBuild:
   1. CodeBuild is set to run buildspec.yml script that will:
       1. Pull image, tag it and push it to ECS. - This is hashed by default.
       2. Build task definition with the environment variables, register it and export it as artifact.
       3. Build appspec.yml file and export it as artifact.
   2. A role is set to use the ssm parameters, ECS - to register task definition, custome universal policy for codebuild.

7. Cloudfront:
   * Cloudfront uses S3 as an endpoint, it supports http and https based on the load balancer's listener port. However, if HTTPS is used then it is recmmended to use ALB that listens to port 443 - so it terminates the ssl before forwarding it to the target group as ALB is based on layer 7 - and make the target group use port 80 and adjust the vikunja to use the same port. As NLB terminates the ssl cert in layer 4, at the backend of the instances, means the instance needs an ssl cert installed and used for the vikunja while adjusting the app to listen to port 443. A workaround - which is not efficient, is to connect cloudfront of https to the nlb that will be used as a backend endpoint, as cloudfront decrypts ssl before forwarding data.
