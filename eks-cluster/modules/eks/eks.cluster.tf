resource "aws_eks_cluster" "this" {
  name    = var.cluster_name
  version = var.cluster_version

  role_arn = aws_iam_role.eks_cluster.arn

  enabled_cluster_log_types = [
    #"api",
    #"audit",
    "authenticator",
    #"controllerManager",
    #"scheduler"
  ]



  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}