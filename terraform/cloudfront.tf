#############################################
# CloudFront + Route53 for Online Boutique
# Origin: Kubernetes Service type LoadBalancer
# Service: default/frontend-external (HTTP:80)
#############################################

# -------- Variables --------


locals {
  site_domain = coalesce(var.site_domain, "app.${var.domain_name}")
}

# -------- Discover the Service LB hostname --------
# Requires the kubernetes provider to be configured against your EKS cluster.
# If you used the null_resource to deploy the app, keep depends_on so TF reads after deploy.
data "kubernetes_service" "frontend_external" {
  metadata {
    name      = "frontend-external"  # change if your svc name differs
    namespace = "default"            # change if your ns differs
  }
  depends_on = [null_resource.deploy_online_boutique]  # uncomment if you used that resource
}

locals {
  frontend_lb_hostname = try(
    data.kubernetes_service.frontend_external.status[0].load_balancer[0].ingress[0].hostname,
    null
  )
}

# -------- Providers --------
# CloudFront certificates MUST be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# -------- Route 53 Zone --------
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

# -------- ACM Certificate (us-east-1) for CloudFront --------
resource "aws_acm_certificate" "cf" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  tags                      = var.tags
}

# DNS validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cf.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cf" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cf.arn
  validation_record_fqdns = [
    for rec in aws_route53_record.cert_validation : rec.fqdn
  ]
}

# -------- CloudFront Distribution (origin = Service LB hostname) --------
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  comment             = "Online Boutique @ ${local.site_domain} -> Service LB -> EKS"
  price_class         = var.cf_price_class
  aliases             = [local.site_domain]
  wait_for_deployment = true
  tags                = var.tags

  origin {
    domain_name = local.frontend_lb_hostname       # e.g., a1b2c3...elb.amazonaws.com
    origin_id   = "frontend-origin"

    # Since the Service is HTTP:80 (no TLS on origin in Option A)
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"         # switch to "https-only" if you later use ALB+Ingress+TLS
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "frontend-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # Forward everything for a dynamic UI; you can tighten later
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

  # Don’t try to create until the Service has a hostname
  lifecycle {
    precondition {
      condition     = local.frontend_lb_hostname != null && local.frontend_lb_hostname != ""
      error_message = "Frontend LoadBalancer hostname not ready. Ensure Service 'frontend-external' has an external hostname, then re-apply."
    }
  }
}

# -------- Route 53 alias A/AAAA -> CloudFront --------
resource "aws_route53_record" "site_alias_a" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.site_domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_alias_aaaa" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.site_domain
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# -------- Helpful Outputs --------
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
