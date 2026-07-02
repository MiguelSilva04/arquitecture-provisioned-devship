terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
  #  backend "s3" {
  #    bucket       = "workshop-march-terraform-state-bucket-090172996063"
  #    key          = "eks-cluster/terraform.tfstate"
  #    region       = "us-east-1"
  #    use_lockfile = true
  #    profile      = "workshop"
  # dynamodb_table = "workshop-march-state-locking-table"
  #  }
}

module "networking" {
  source = "./modules/networking"

  tags = var.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  subnet_ids          = module.networking.public_subnet_ids
  cluster_role        = var.cluster_role
  ecr_repositories    = var.ecr_repositories
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  devship_role_arn    = var.devship_role_arn
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}
