# Will Connect to S3 static site
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
resource "aws_cloudfront_origin_access_control" "origin" {
  name                              = var.vpc_name
  description                       = "${var.vpc_name}-Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "distribution_main" {
  origin {
    domain_name              = "${aws_s3_bucket.bucket.bucket_domain_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.origin.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "allow-all" # For HTTP & HTTPS
    # Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    # Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    # Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html#managed-response-headers-policies-cors
    response_headers_policy_id = "5cc3b908-e619-4b99-88e5-2cf7f45965bd"
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "main"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
