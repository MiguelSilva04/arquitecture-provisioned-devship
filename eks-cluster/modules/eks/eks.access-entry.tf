resource "aws_eks_access_entry" "devship" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.devship_role_arn
  type          = "STANDARD"

  depends_on = [
    aws_eks_cluster.this
  ]
}

resource "aws_eks_access_policy_association" "devship_view" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.devship_role_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.devship
  ]
}

resource "aws_eks_access_entry" "cloud_engineer" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cloud_engineer_principal_arn
  type          = "STANDARD"

  depends_on = [
    aws_eks_cluster.this
  ]
}

resource "aws_eks_access_policy_association" "cloud_engineer_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cloud_engineer_principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.cloud_engineer
  ]
}