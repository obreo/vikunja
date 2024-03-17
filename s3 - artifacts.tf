# S3 Bucket
resource "aws_s3_bucket" "bucket_artifact" {
  bucket = "${var.bucket_name}-artifacts"
}

# Disable bucket ACLs to allow bucket policy
resource "aws_s3_bucket_ownership_controls" "control" {
  bucket = aws_s3_bucket.bucket_artifact.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "acl" {
  bucket = aws_s3_bucket.bucket_artifact.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.control,
    aws_s3_bucket_public_access_block.acl,
  ]

  bucket = aws_s3_bucket.bucket_artifact.id
  acl    = "public-read"
}


## Bucket policy
resource "aws_s3_bucket_policy" "allow_access" {
  bucket = aws_s3_bucket.bucket_artifact.id
  policy = data.aws_iam_policy_document.allow_access_s3.json
}

data "aws_iam_policy_document" "allow_access_s3" {
  statement {
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "codepipeline.amazonaws.com",
        "codedeploy.amazonaws.com",
        "codebuild.amazonaws.com",
        "cloudformation.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucket",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      aws_s3_bucket.bucket_artifact.arn,
      "${aws_s3_bucket.bucket_artifact.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${var.account_id}"]
    }
  }
}
