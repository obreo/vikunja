# This is used to defiine green/blue deployment for ecs using codedeploy. ECS service depends on this resource to run under CodeDeploy configuration.
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group
# Doc: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html

resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "${var.vpc_name}-backend"
}

resource "aws_codedeploy_deployment_group" "group" {
  app_name = aws_codedeploy_app.app.name
  # Application deployment method to instances - whether gradually or all at once
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = var.vpc_name
  service_role_arn       = aws_iam_role.codeDeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }
  # Traffic shift from blue to green method
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.fargate.name
    service_name = aws_ecs_service.service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }
}

######################################################
# CodeDeploy-ECS Execution Role
######################################################
resource "aws_iam_role" "codeDeploy_role" {
  name               = "codeDeploy_ECS_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.codeDeploy_role.json
}

# Assumed role (resource) used for the role
data "aws_iam_policy_document" "codeDeploy_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
#Policy Attachment
resource "aws_iam_policy_attachment" "codeDeploy_role" {
  name       = "ecs_task_execution_role"
  roles      = ["${aws_iam_role.codeDeploy_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_iam_policy_attachment" "codeDeploy_role_2" {
  name       = "Custome Policy to access S3"
  roles      = ["${aws_iam_role.codeDeploy_role.name}"]
  policy_arn = aws_iam_policy.codedeploy-custom-policy.arn
}
#####################################################
# End of Role
#####################################################

# Custome Policy to access S3:
resource "aws_iam_policy" "codedeploy-custom-policy" {
  name        = "codedeploy-custom-policy"
  path        = "/"
  description = "Custome Policy to access S3"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Additionals"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "cloudformation:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketPolicy",
          "s3:PutObjectAcl",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}-artifacts/*",
          "arn:aws:s3:::${var.bucket_name}-artifacts"
        ]
      },
      {
        Sid    = "Artifacts"
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::codepipeline-us-east-1-*"
        ]
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      }
    ]
  })

}
