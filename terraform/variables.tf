variable "region" {
  type        = string
  default     = "ca-central-1"
  description = "AWS region"
}

variable "cidr_block" {
  type    = string
  default = "10.10.0.0/16"
}

variable "tags" {
  type = map(string)
  default = {
    terraform  = "true"
    kubernetes = "cloudops-eks-cluster"
  }
  description = "Tags to apply to all resources"
}

variable "eks_version" {
  type        = string
  default     = "1.31"
  description = "EKS version"
}

variable "cluster_name" {
  type        = string
  default     = "cloudops-eks-platform"
  description = "EKS cluster name value"
}

# --- CloudFront/Route53 vars moved here ---
variable "domain_name" {
  description = "Root domain (public hosted zone exists). Example: bekarys2003.com"
  type        = string
}

variable "site_domain" {
  description = "FQDN users hit (alias to CloudFront). Example: app.bekarys2003.com"
  type        = string
  default     = null
}

variable "cf_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "enable_ipv6" {
  description = "Enable IPv6 on CloudFront"
  type        = bool
  default     = true
}
