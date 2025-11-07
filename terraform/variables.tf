variable "region" {
type = string
default = "ca-central-1"
description = "AWS region"
}

variable "cidr_block" {
type = string
default = "10.10.0.0/16"

}

variable "tags" {
type = map(string)
default = {
    terraform  = "true"
    kubernetes = "demo-eks-cluster"
}
description = "Tags to apply to all resources"
}

variable "eks_version" {
type = string
default = "1.31"
description = "EKS version"
}

variable "cluster_name" {
type = string
default = "cloudops-eks-platform"
description = "EKS cluster name value"
}


