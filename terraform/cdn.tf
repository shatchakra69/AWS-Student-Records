# ---------------------------------------------------------------------------
# Optional edge layer: Amazon CloudFront + AWS WAF in front of the ALB.
#
# Disabled by default. Set `enable_cdn = true` to deploy it. It adds:
#   - HTTPS at the edge (CloudFront default certificate, no custom domain needed)
#   - a global CDN / single front door for the app
#   - AWS WAF managed rules + IP rate limiting
#
# Note: a CLOUDFRONT-scoped WAF Web ACL must be created in us-east-1, which is
# this configuration's default region.
# ---------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "cdn" {
  count = var.enable_cdn ? 1 : 0
  name  = "${local.name_prefix}-cf-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS-managed baseline protections (OWASP-style common rule set).
  rule {
    name     = "common-rule-set"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Per-IP rate limit to blunt floods / scraping.
  rule {
    name     = "rate-limit"
    priority = 2
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-cf-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  count      = var.enable_cdn ? 1 : 0
  enabled    = true
  comment    = "${local.name_prefix} edge (CloudFront + WAF) in front of the ALB"
  web_acl_id = aws_wafv2_web_acl.cdn[0].arn

  # US + Europe edge locations only (cheapest tier).
  price_class = "PriceClass_100"

  origin {
    domain_name = aws_lb.app.dns_name
    origin_id   = "alb"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB listens on HTTP; TLS terminates at CloudFront
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    # Managed policies (stable AWS-wide IDs):
    #   CachingDisabled  - dynamic CRUD pages are not cached
    #   AllViewer        - forward all headers, cookies, and query strings to the app
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "${local.name_prefix}-cdn" }
}
