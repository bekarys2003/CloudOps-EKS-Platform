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
  default     = "1.32"
  description = "EKS version"
}

variable "cluster_name" {
  type        = string
  default     = "cloudops-eks-platform"
  description = "EKS cluster name value"
}

variable "domain_name" {
  description = "Root domain (public hosted zone exists). Example: bekarys2003.com"
  default   = "bekarys2003.com"
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



variable "github_org" {
    type      = string
    default   = "bekarys2003"
}
variable "github_repo" {
    type      = string
    default   = "microservices-demo"
}

variable "github_token" {
    type = string

}

variable "branch" {
    type = string
    default = "main"
}

variable "boutique_services" {
  type    = set(string)
  default = [
    "adservice","cartservice","checkoutservice","currencyservice","emailservice",
    "frontend","paymentservice","productcatalogservice","recommendationservice",
    "shippingservice"
  ]
}
