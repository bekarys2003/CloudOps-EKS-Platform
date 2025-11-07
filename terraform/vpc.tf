data "aws_availability_zones" "available" {
state = "available"
}

resource "aws_vpc" "demo-eks-cluster-vpc" {
cidr_block = var.cidr_block
enable_dns_hostnames = true
tags = var.tags
}

locals {
  public_additional_tags = {
    "kubernetes.io/role/elb" = "1",
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
  private_additional_tags = {
    "kubernetes.io/role/internal-elb" = "1",
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}


resource "aws_subnet" "public-subnet-1" {
vpc_id     = aws_vpc.demo-eks-cluster-vpc.id
cidr_block = cidrsubnet(var.cidr_block, 8, 10)
availability_zone = data.aws_availability_zones.available.names[0]
tags = merge(var.tags, local.public_additional_tags)
}

resource "aws_subnet" "public-subnet-2" {
vpc_id     = aws_vpc.demo-eks-cluster-vpc.id
cidr_block = cidrsubnet(var.cidr_block, 8, 20)
availability_zone = data.aws_availability_zones.available.names[1]
tags = merge(var.tags, local.public_additional_tags)
}

resource "aws_subnet" "private-subnet-1" {
vpc_id     = aws_vpc.demo-eks-cluster-vpc.id
cidr_block = cidrsubnet(var.cidr_block, 8, 110)
availability_zone = data.aws_availability_zones.available.names[0]
tags = merge(var.tags, local.private_additional_tags)
}

resource "aws_subnet" "private-subnet-2" {
vpc_id     = aws_vpc.demo-eks-cluster-vpc.id
cidr_block = cidrsubnet(var.cidr_block, 8, 120)
availability_zone = data.aws_availability_zones.available.names[1]

tags = merge(var.tags, local.private_additional_tags)
}

resource "aws_internet_gateway" "eks-igw" {
vpc_id = aws_vpc.demo-eks-cluster-vpc.id

tags = var.tags
}

resource "aws_eip" "eks-ngw-eip_a" {
domain = "vpc"

tags = var.tags
depends_on = [aws_internet_gateway.eks-igw]
}

resource "aws_eip" "eks-ngw-eip_b" {
domain = "vpc"

tags = var.tags
depends_on = [aws_internet_gateway.eks-igw]
}

resource "aws_nat_gateway" "eks-ngw_a" {
allocation_id = aws_eip.eks-ngw-eip_a.id
subnet_id     = aws_subnet.public-subnet-1.id

depends_on = [aws_internet_gateway.eks-igw]
tags = var.tags
}

resource "aws_nat_gateway" "eks-ngw_b" {
allocation_id = aws_eip.eks-ngw-eip_b.id
subnet_id     = aws_subnet.public-subnet-2.id

depends_on = [aws_internet_gateway.eks-igw]
tags = var.tags
}

resource "aws_route_table" "public-rt" {
vpc_id = aws_vpc.demo-eks-cluster-vpc.id

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-igw.id
}
tags = var.tags
}

resource "aws_route_table"  "private-rt-a" {
vpc_id = aws_vpc.demo-eks-cluster-vpc.id

route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks-ngw_a.id
}
tags = var.tags
}

resource "aws_route_table"  "private-rt-b" {
vpc_id = aws_vpc.demo-eks-cluster-vpc.id

route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks-ngw_b.id
}
tags = var.tags
}

resource "aws_route_table_association" "public-rt-assoc-1" {
subnet_id      = aws_subnet.public-subnet-1.id
route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public-rt-assoc-2" {
subnet_id      = aws_subnet.public-subnet-2.id
route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private-rt-assoc-1" {
subnet_id      = aws_subnet.private-subnet-1.id
route_table_id = aws_route_table.private-rt-a.id
}

resource "aws_route_table_association" "private-rt-assoc-2" {
subnet_id      = aws_subnet.private-subnet-2.id
route_table_id = aws_route_table.private-rt-b.id
}