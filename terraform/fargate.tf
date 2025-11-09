resource "aws_iam_role" "cloudops-eks-fargate-profile-role" {
  name = "cloudops-eks-fargate-profile-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fargate-execution-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.cloudops-eks-fargate-profile-role.name
}

resource "aws_eks_fargate_profile" "cloudops-eks-fg-prof" {
  cluster_name           = aws_eks_cluster.cloudops-eks-platform.name
  fargate_profile_name   = "cloudops-eks-fargate-profile-1"
  pod_execution_role_arn = aws_iam_role.cloudops-eks-fargate-profile-role.arn

  selector {
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kube-dns"
    }
  }

  subnet_ids = [
    aws_subnet.private-subnet-1.id,
    aws_subnet.private-subnet-2.id
  ]

  depends_on = [aws_iam_role_policy_attachment.fargate-execution-policy]
}
