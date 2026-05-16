locals {
  bucket_name            = coalesce(var.bucket_name, "${var.name_prefix}-ui")
  oac_name               = coalesce(var.origin_access_control_name, "${var.name_prefix}-ui-oac")
  cache_policy_name      = coalesce(var.cache_policy_name, "${var.name_prefix}-ui-cache")
  has_acm_certificate    = var.acm_certificate_arn != null
  has_aliases            = length(var.aliases) > 0
  use_custom_certificate = local.has_acm_certificate && local.has_aliases
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = var.kms_key_arn != null

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = local.oac_name
  description                       = "OAC for ${local.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket.json
}

resource "aws_cloudfront_cache_policy" "this" {
  name        = local.cache_policy_name
  comment     = "Cache policy for ${var.name_prefix} SPA distribution"
  min_ttl     = var.cache_policy.min_ttl
  default_ttl = var.cache_policy.default_ttl
  max_ttl     = var.cache_policy.max_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = var.cache_policy.enable_accept_encoding_brotli
    enable_accept_encoding_gzip   = var.cache_policy.enable_accept_encoding_gzip

    cookies_config {
      cookie_behavior = var.cache_policy.cookie_behavior

      dynamic "cookies" {
        for_each = length(var.cache_policy.cookies) > 0 ? [1] : []
        content {
          items = var.cache_policy.cookies
        }
      }
    }

    headers_config {
      header_behavior = var.cache_policy.header_behavior

      dynamic "headers" {
        for_each = length(var.cache_policy.headers) > 0 ? [1] : []
        content {
          items = var.cache_policy.headers
        }
      }
    }

    query_strings_config {
      query_string_behavior = var.cache_policy.query_string_behavior

      dynamic "query_strings" {
        for_each = length(var.cache_policy.query_strings) > 0 ? [1] : []
        content {
          items = var.cache_policy.query_strings
        }
      }
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = var.ipv6_enabled
  comment             = coalesce(var.comment, "${var.name_prefix} SPA distribution")
  default_root_object = var.default_root_object
  http_version        = var.http_version
  price_class         = var.price_class
  web_acl_id          = var.web_acl_id
  aliases             = var.aliases

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.this.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.this.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.this.id
  }

  dynamic "custom_error_response" {
    for_each = var.spa_error_responses ? [403, 404] : []

    content {
      error_code            = custom_error_response.value
      response_code         = 200
      response_page_path    = "/${trim(var.default_root_object, "/")}"
      error_caching_min_ttl = var.spa_error_caching_min_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction.restriction_type
      locations        = var.geo_restriction.locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.use_custom_certificate ? false : true
    acm_certificate_arn            = local.use_custom_certificate ? var.acm_certificate_arn : null
    ssl_support_method             = local.use_custom_certificate ? "sni-only" : null
    minimum_protocol_version       = local.use_custom_certificate ? var.minimum_protocol_version : "TLSv1"
  }

  dynamic "logging_config" {
    for_each = var.logging == null ? [] : [var.logging]

    content {
      bucket          = logging_config.value.bucket
      prefix          = logging_config.value.prefix
      include_cookies = logging_config.value.include_cookies
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ui"
  })

  lifecycle {
    precondition {
      condition     = !local.has_aliases || local.has_acm_certificate
      error_message = "acm_certificate_arn is required when aliases is non-empty. The certificate must be issued in us-east-1."
    }
  }
}
