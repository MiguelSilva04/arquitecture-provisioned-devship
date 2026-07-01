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