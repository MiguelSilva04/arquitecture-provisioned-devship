terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # state próprio, independente do eks-cluster/
  # backend "s3" {
  #   bucket       = "workshop-march-terraform-state-bucket-090172996063"
  #   key          = "public-hosting/terraform.tfstate"
  #   region       = "us-east-1"
  #   use_lockfile = true
  #   profile      = "workshop"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

module "networking" {
  source = "../eks-cluster/modules/networking"

  tags = var.tags
  vpc = {
    name                    = "devship-public-vpc"
    cidr_block              = "10.1.0.0/24"
    internet_gateway_name   = "devship-public-igw"
    public_route_table_name = "devship-public-rt"
    public_subnets = [
      {
        name                    = "devship-public-subnet-${var.availability_zone}"
        cidr_block              = "10.1.0.0/26"
        availability_zone       = var.availability_zone
        map_public_ip_on_launch = true
      }
    ]
  }
}
