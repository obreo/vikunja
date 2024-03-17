# S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}-frontend"
}

# Disable bucket ACLs to allow bucket policy
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


## Bucket policy
resource "aws_s3_bucket_policy" "allow_access_static" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.allow_access_static.json
}

data "aws_iam_policy_document" "allow_access_static" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }

  # For a better practice, we'll allow PUT requests only through the website
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]

    condition {
      test     = "StringLike"
      variable = "aws:Referer"
      values   = ["${aws_s3_bucket.bucket.bucket_regional_domain_name}/*", "${aws_cloudfront_distribution.distribution_main.domain_name}/*"]
    }
  }
}

# Static site settings
resource "aws_s3_bucket_website_configuration" "static" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

/*
# S3 Objects
# Doc: https://stackoverflow.com/questions/76170291/how-do-i-specify-multiple-content-types-to-my-s3-object-using-terraform
locals {
  folder_path = "./frontend" # Update this with the path to your folder
  files       = fileset(local.folder_path, "**//*")
  # Content type mappings
  content_type_map = {
    ".js"          = "text/javascript"
    ".map"         = "binary/octet-stream"
    ".png"         = "image/png"
    ".svg"         = "image/svg+xml"
    ".mjs"         = "text/javascript"
    ".css"         = "text/css"
    ".jpg"         = "image/jpeg"
    ".woff2"       = "binary/octet-stream"
    ".ico"         = "image/x-icon"
    ".txt"         = "text/plain"
    ".webmanifest" = "binary/octet-stream"
    ".html"        = "text/html"
    # Add more mappings as needed
  }
}

resource "aws_s3_bucket_object" "object" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "text/javascript")
}

resource "aws_s3_bucket_object" "object2" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "binary/octet-stream")
}

resource "aws_s3_bucket_object" "object3" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "image/png")
}

resource "aws_s3_bucket_object" "object4" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "image/svg+xml")
}

resource "aws_s3_bucket_object" "object5" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "text/css")
}

resource "aws_s3_bucket_object" "object6" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "image/jpeg")
}

resource "aws_s3_bucket_object" "object7" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "image/x-icon")
}

resource "aws_s3_bucket_object" "object8" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "text/plain")
}

resource "aws_s3_bucket_object" "object9" {
  for_each     = { for file in local.files : file => file }
  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${local.folder_path}/${each.value}"
  etag         = filemd5("${local.folder_path}/${each.value}")
  content_type = lookup(local.content_type_map, split(".", "${local.folder_path}/${each.value}")[1], "text/html")
}
*/

/*
resource "aws_s3_object" "object" {
  for_each = { for file in local.files : file => file }
  bucket   = aws_s3_bucket.bucket.id
  key      = each.value
  source   = "${local.folder_path}/${each.value}"
}
*/