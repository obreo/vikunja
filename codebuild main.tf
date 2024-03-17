# Reference doc: https://registry.terraform.io/providers/hashicorpcodebuild_name/aws/latest/docs/resources/codebuild_project
# Reference doc: https://docs.aws.amazon.com/codebuild/latest/APIReference/API_Types.html
# Reference doc: https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html
resource "aws_codebuild_project" "codebuild_main" {
  name          = "${var.codebuild_name}-main"
  description   = var.codebuild_description
  build_timeout = 10 #min
  service_role  = aws_iam_role.codebuild-role.arn

  # Doc: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-codebuild-project-artifacts.html
  artifacts {
    type                = "S3"
    packaging           = "NONE"
    path                = "artifacts"
    namespace_type      = "BUILD_ID"
    name                = "build_artifact"
    encryption_disabled = true
    location            = aws_s3_bucket.bucket_artifact.id
  }

  # You can save time when your project builds by using a cache. A cache can store reusable pieces of your build environment and use them across multiple builds. 
  # Your build project can use one of two types of caching: Amazon S3 or local. 
  /*
  cache {
    type     = "S3"
    location = aws_s3_bucket.elb.bucket
  }
*/
  environment {
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
    compute_type = "BUILD_GENERAL1_SMALL"
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html#environment.types
    # For Lmbda computes: Only available for environment type LINUX_LAMBDA_CONTAINER and ARM_LAMBDA_CONTAINER
    type = "LINUX_CONTAINER"
    # When you use a cross-account or private registry image, you must use SERVICE_ROLE credentials. When you use an AWS CodeBuild curated image, you must use CODEBUILD credentials.
    image_pull_credentials_type = "CODEBUILD"
    # Environment Variables

    # 1
    environment_variable {
      name  = var.env-name-a #username
      value = aws_ssm_parameter.RDS.arn
    }
    # 2
    environment_variable {
      name  = var.env-name-b              #password
      value = aws_ssm_parameter.RDS_2.arn # password env > value is in ssm
    }
    # 3
    environment_variable {
      name  = var.env-name-c #host
      value = aws_db_instance.rds.endpoint
    }
    # 4
    environment_variable { #db engine
      name  = var.env-name-d
      value = var.env-value-d
    }
    # 5
    environment_variable {
      name  = var.env-name-e
      value = aws_s3_bucket_website_configuration.static.website_endpoint
    }
    # 6
    environment_variable {
      name  = var.env-name-f
      value = var.env-value-f
    }
    # 7
    environment_variable {
      name  = var.env-name-g
      value = var.env-value-g
    }
  }


  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-log-group"
      stream_name = "codebuild-log-stream"
    }
  }
  # Doc: https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-ecs-ecr-codedeploy.html#tutorials-ecs-ecr-codedeploy-taskdefinition
  source {
    type      = "NO_SOURCE"
    buildspec = <<EOF
      # This is a buildspec script will pull vikunja image, then tag it and push it to ecr. Then 
      # Make sure that CodeBuild has role to access all the resources mentioned in this script so it can use awscli without authentication.
      version: 0.2
      phases:
        pre_build:
          commands:
            # Log in ECR
            - aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.us-east-1.amazonaws.com
        build:
          commands:
            # Pulling image
            #- echo  'Pulling Image'
            #- docker pull ${var.image_name}
        post_build:
          commands:
            # Pushing image to repository
            #- echo 'Pushing Image to ECR repository & updating the tag'
            #- docker tag ${var.image_name}:latest ${var.account_id}.dkr.ecr.us-east-1.amazonaws.com/${var.ecr_name}-main:$${CODEBUILD_BUILD_NUMBER}
            #- docker push ${var.account_id}.dkr.ecr.us-east-1.amazonaws.com/${var.ecr_name}-main:$${CODEBUILD_BUILD_NUMBER}
            # Creating a new task definition
            - echo Creating task definition file...
            - |
              cat << END > taskdef.json
              {
                "family": "${var.vpc_name}",
                "containerDefinitions": [
                  {
                    "name": "${var.vpc_name}",
                    "image": "${var.image_name}",
                    "essential": true,
                    "cpu": 0,
                    "logConfiguration": {
                        "logDriver": "awslogs",
                        "options": {
                            "awslogs-group": "${var.vpc_name}",
                            "awslogs-region": "${var.region}",
                            "awslogs-create-group": "true",
                            "awslogs-stream-prefix": "${var.vpc_name}"
                        }
                    },
                    "portMappings": [
                      {
                        "containerPort": ${var.task_port},
                        "hostPort": ${var.task_port}
                      }
                    ],
                    "environment": [
                      {
                        "name": "${var.env-name-c}",
                        "value": "$${${var.env-name-c}}"
                      },
                      {
                        "name": "${var.env-name-d}",
                        "value": "$${${var.env-name-d}}"
                      },
                      {
                        "name": "${var.env-name-e}",
                        "value": "$${${var.env-name-e}}"
                      },
                      {
                        "name": "${var.env-name-f}",
                        "value": "$${${var.env-name-f}}"
                      },
                      {
                        "name": "${var.env-name-g}",
                        "value": "$${${var.env-name-g}}"
                      }
                    ],
                      "secrets": [
                      {
                          "name": "${var.env-name-a}",
                          "valueFrom": "$${${var.env-name-a}}"
                      },
                      {
                          "name": "${var.env-name-b}",
                          "valueFrom": "$${${var.env-name-b}}"
                      }
                    ]
                  }
                ],
                "networkMode": "awsvpc",
                "requiresCompatibilities": ["FARGATE"],
                "cpu": "512",
                "memory": "1024",
                "executionRoleArn": "${aws_iam_role.ecs_task_execution_role.arn}",
                "taskRoleArn": "${aws_iam_role.ecs_task_execution_role.arn}"
              }
              END
            - echo "updating task definition..."
            - aws ecs register-task-definition --region ${var.region} --cli-input-json file://taskdef.json --query 'taskDefinition.taskDefinitionArn' --output text
            - REVISION=$(aws ecs describe-task-definition --task-definition ${var.vpc_name} --query 'taskDefinition.revision')
            # Write the new appspec.yml
            - echo "Building appspec.yml"
            - |
              cat << END > appspec.yml
              version: 0.0
              Resources:
                - TargetService:
                    Type: AWS::ECS::Service
                    Properties:
                      TaskDefinition: "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${var.vpc_name}:$REVISION"
                      LoadBalancerInfo:
                        ContainerName: "${var.vpc_name}"
                        ContainerPort: ${var.task_port}

              END
      artifacts:
        files:
          - taskdef.json
          - appspec.yml
    
    EOF
  }
}
