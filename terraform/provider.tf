terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}


provider "aws" {
    region = var.region
}


# Get cluster connection details
data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.cloudops-eks-platform.name
}
data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.cloudops-eks-platform.name
}

# Terraform talks to the cluster directly (no kubeconfig file needed)
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}