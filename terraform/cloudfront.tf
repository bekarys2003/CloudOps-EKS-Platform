
locals {
  site_domain = coalesce(var.site_domain, "app.${var.domain_name}")
}

data "kubernetes_service" "frontend_external" {
  metadata {
    name      = "frontend-external"
    namespace = "default"
  }
  depends_on = [null_resource.deploy_online_boutique]
}

locals {
  frontend_lb_hostname = try(
    data.kubernetes_service.frontend_external.status[0].load_balancer[0].ingress[0].hostname,
    null
  )
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# --- ACM Certificate  ---
resource "aws_acm_certificate" "cf" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  tags                      = var.tags
}


resource "aws_acm_certificate_validation" "cf" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cf.arn
  validation_record_fqdns = [
    for rec in aws_route53_record.cert_validation : rec.fqdn
  ]
}


resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  comment             = "Online Boutique @ ${local.site_domain} -> Service LB -> EKS"
  price_class         = var.cf_price_class
  aliases             = [local.site_domain]
  wait_for_deployment = true
  tags                = var.tags

  origin {
    domain_name = local.frontend_lb_hostname
    origin_id   = "frontend-origin"

    # Using Service type=LoadBalancer (HTTP:80). Switch to https-only if you move to ALB+Ingress+TLS.
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "frontend-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies { forward = "all" }
    }

    compress = true
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cf.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  lifecycle {
    precondition {
      condition     = local.frontend_lb_hostname != null && local.frontend_lb_hostname != ""
      error_message = "Frontend LoadBalancer hostname not ready. Ensure Service 'frontend-external' has a hostname, then re-apply."
    }
  }
}

# --- Outputs ---
output "frontend_lb_hostname" {
  value       = local.frontend_lb_hostname
  description = "Kubernetes Service LoadBalancer hostname used as CloudFront origin"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.site.domain_name
  description = "CloudFront distribution domain"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.site.id
  description = "CloudFront distribution ID"
}
