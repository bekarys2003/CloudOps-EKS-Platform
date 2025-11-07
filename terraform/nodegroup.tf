resource "aws_iam_role" "cloudops-eks-ng-role" {
  name = "cloudops-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks-cloudops-ng-WorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.cloudops-eks-ng-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cloudops-ng-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.cloudops-eks-ng-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cloudops-ng-ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.cloudops-eks-ng-role.name
}

resource "aws_eks_node_group" "eks-cloudops-node-group_a" {
  cluster_name    = var.cluster_name
  node_role_arn   = aws_iam_role.cloudops-eks-ng-role.arn
  node_group_name = "cloudops-eks-node-group-a"

  subnet_ids = [
    aws_subnet.private-subnet-1.id,
  ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_cluster.cloudops-eks-platform,
    aws_iam_role_policy_attachment.eks-cloudops-ng-WorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-cloudops-ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-cloudops-ng-ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_node_group" "eks-cloudops-node-group_b" {
  cluster_name    = var.cluster_name
  node_role_arn   = aws_iam_role.cloudops-eks-ng-role.arn
  node_group_name = "cloudops-eks-node-group-b"

  subnet_ids = [
    aws_subnet.private-subnet-2.id,
  ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_cluster.cloudops-eks-platform,
    aws_iam_role_policy_attachment.eks-cloudops-ng-WorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-cloudops-ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-cloudops-ng-ContainerRegistryReadOnly,
  ]
}
