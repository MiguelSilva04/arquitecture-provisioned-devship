data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

data "aws_ecr_authorization_token" "this" {}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "apps" {
  for_each = toset(["dev", "staging", "prod"])

  metadata {
    name = each.value
  }
}

resource "kubernetes_secret" "ecr" {
  for_each = kubernetes_namespace.apps

  metadata {
    name      = "ecr-secret"
    namespace = each.value.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com" = {
          auth = data.aws_ecr_authorization_token.this.authorization_token
        }
      }
    })
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
}

resource "time_sleep" "wait_for_argocd_crds" {
  depends_on      = [helm_release.argocd]
  create_duration = "30s"
}

data "http" "argocd_apps" {
  for_each = toset(["dev", "staging", "prod"])
  url      = "https://raw.githubusercontent.com/MiguelSilva04/devship-gitops/principal/apps/argocd-applications/${each.value}-application.yaml"
}

resource "kubectl_manifest" "argocd_apps" {
  for_each   = data.http.argocd_apps
  yaml_body  = each.value.response_body
  depends_on = [time_sleep.wait_for_argocd_crds, kubernetes_namespace.apps]
}