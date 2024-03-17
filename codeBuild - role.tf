# Attach this role with codebuild application and check the option that allows role modification while codebuild app environment creation.


# Service Role to pass
resource "aws_iam_role" "codebuild-role" {
  name               = var.codebuild_role_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.codebuild-service-role.json
}

# Assumed role (resource) used for the role
data "aws_iam_policy_document" "codebuild-service-role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy_attachment" "codebuild_policy_1" {
  name       = "codebuild_policy_1"
  roles      = ["${aws_iam_role.codebuild-role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_policy_attachment" "codebuild_policy_3" {
  name       = "codebuild_policy_3"
  roles      = ["${aws_iam_role.codebuild-role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}


resource "aws_iam_policy_attachment" "codebuild_policy_2" {
  name       = "codebuild_policy_2"
  roles      = ["${aws_iam_role.codebuild-role.name}"]
  policy_arn = aws_iam_policy.codebuild-role-policy.arn
}


####################################

resource "aws_iam_policy" "codebuild-role-policy" {
  name        = "${var.codebuild_role_name}-policy"
  path        = "/"
  description = "Additional policies required for codebuild cicd"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECR"
        Effect = "Allow"
        Action = [
          "ecr:PutLifecyclePolicy",
          "ecr:PutImageTagMutability",
          "ecr:DescribeImageScanFindings",
          "ecr:StartImageScan",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImageScanningConfiguration",
          "ecr:DescribeImageReplicationStatus",
          "ecr:ListTagsForResource",
          "ecr:UploadLayerPart",
          "ecr:BatchDeleteImage",
          "ecr:BatchGetRepositoryScanningConfiguration",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:StartLifecyclePolicyPreview",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:ReplicateImage",
          "ecr:GetRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DescribeRepositoryCreationTemplate",
          "ecr:GetRegistryPolicy",
          "ecr:CreateRepository",
          "ecr:DescribeRegistry",
          "ecr:GetAuthorizationToken",
          "ecr:PutRegistryScanningConfiguration",
          "ecr:CreatePullThroughCacheRule",
          "ecr:GetRegistryScanningConfiguration",
          "ecr:ValidatePullThroughCacheRule",
          "ecr:CreateRepositoryCreationTemplate",
          "ecr:BatchImportUpstreamImage",
          "ecr:UpdatePullThroughCacheRule",
          "ecr:PutReplicationConfiguration"
        ]
        Resource = "*"
      },
      {
        Sid    = "Additionals"
        Effect = "Allow"
        Action = [
          "elasticbeanstalk:*",
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
        Sid    = "Logs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["*"]
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
      },
      {
        Sid    = "Additionals2"
        Effect = "Allow"
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ]
        Resource = [
          "arn:aws:codebuild:us-east-1:${var.account_id}:report-group/*"
        ]
      }
    ]
  })

}
