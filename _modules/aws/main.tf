terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.53.0"
    }
  }
}

resource "aws_s3_bucket" "main_bucket" {
  bucket = local.full
}

resource "aws_s3_object" "dist" {
  for_each = fileset(var.src_dir, "**")

  bucket = aws_s3_bucket.main_bucket.id
  key    = each.value
  source = "${var.src_dir}${each.value}"

  content_type = endswith("${each.value}", ".html") ? "text/html" : null
  # etag makes the file update when it changes; see https://stackoverflow.com/questions/56107258/terraform-upload-file-to-s3-on-every-apply
  etag   = filemd5("${var.src_dir}${each.value}")
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.main_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.main_bucket.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::${aws_s3_bucket.main_bucket.id}/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "arn:aws:cloudfront::${data.aws_caller_identity.current.id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
            }
        }
    }
  })
}

locals {
  s3_origin_id = "S3-${aws_s3_bucket.main_bucket.bucket}"
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3_access_control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = local.full
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

#   logging_config {
#     include_cookies = false
#     bucket          = "mylogs.s3.amazonaws.com"
#     prefix          = "myprefix"
#   }
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.main_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true


  aliases = [local.full, local.naked]
  default_root_object = "index.html"

  default_cache_behavior {
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = local.s3_origin_id
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.cert.arn
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }
}