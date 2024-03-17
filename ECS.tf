# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
# 1. Cluster
resource "aws_ecs_cluster" "fargate" {
  name = var.vpc_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.log.name
      }
    }
  }
}

# 1.1 Logs to Cloudwatch
resource "aws_cloudwatch_log_group" "log" {
  name = var.vpc_name
}

# Doc:Fragate: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html
# Doc:EC2: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider
# 2. Capacity Provider
## Fargate
resource "aws_ecs_cluster_capacity_providers" "provider" {
  cluster_name = aws_ecs_cluster.fargate.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    # Doc: https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_CapacityProviderStrategyItem.html
    base              = 0
    weight            = 1
    capacity_provider = "FARGATE"
  }
}

# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
# Doc: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
#3.Task_Definition
resource "aws_ecs_task_definition" "task_def" {
  family                   = var.vpc_name
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  # Assigning role for logs
  task_role_arn = aws_iam_role.ecs_task_execution_role.arn
  # In the environment variables I used value variables as the name variables are supposed to be registered in the codebuild envs section to it will use the values, but here they are managed through terraform only.
  container_definitions = <<TASK_DEFINITION
  [
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
          "value": "${aws_db_instance.rds.endpoint}"
        },
        {
          "name": "${var.env-name-d}",
          "value": "${var.env-value-d}"
        },
        {
          "name": "${var.env-name-e}",
          "value": "${aws_s3_bucket_website_configuration.static.website_endpoint}"
        },
        {
          "name": "${var.env-name-f}",
          "value": "${var.env-value-f}"
        },
        {
          "name": "${var.env-name-g}",
          "value": "${var.env-value-g}"
        }
      ],
      "secrets": [
        {
            "name": "${var.env-name-a}",
            "valueFrom": "${aws_ssm_parameter.RDS.arn}"
        },
        {
            "name": "${var.env-name-b}",
            "valueFrom": "${aws_ssm_parameter.RDS_2.arn}"
        }
      ]
    }
  ]
  TASK_DEFINITION
}


######################################################
# Task Execution Role
######################################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

# Assumed role (resource) used for the role
data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
#Policy Attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "rds" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

#####################################################
# End of Role
#####################################################


# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
#4. Service
resource "aws_ecs_service" "service" {
  name            = var.vpc_name
  cluster         = aws_ecs_cluster.fargate.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.task_def.arn
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY" # Requires IAM role to access ecs cluster
  }

  network_configuration {
    subnets          = [aws_subnet.public-primary-instance.id]
    security_groups  = [aws_security_group.allow_tls.id]
    assign_public_ip = true
  }
  # Doc: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/register-multiple-targetgroups.html

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.vpc_name
    container_port   = var.task_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}


## 4.1 Service AutoScaling
### We'll use Autoscaling application for that:
### Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy
### Doc: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.fargate.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
#### ECS Metrics Doc: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/available_cloudwatch_metrics.html
#### Target scaling policy
resource "aws_appautoscaling_policy" "example" {
  name               = var.vpc_name
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70

    customized_metric_specification {
      metrics {
        label = "${var.vpc_name}-CPUUtilization-metrics"
        id    = "m1"

        metric_stat {
          metric {
            metric_name = "CPUUtilization"
            namespace   = "CPUUtilization"

            dimensions {
              name  = "ClusterName"
              value = aws_ecs_cluster.fargate.name
            }

            dimensions {
              name  = "ServiceName"
              value = aws_ecs_service.service.name
            }
          }

          stat = "Average"
        }

        return_data = true
      }
    }
  }
}
