# variable "assume_role" {
#   type = object({
#     arn    = string
#     region = string
#   })

#   default = {
#     arn    = "arn:aws:iam::306667525254:role/AccessPlatformDevShip"
#     region = "us-east-1"
#   }
# }

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "devship-eks-cluster"
}

variable "cluster_role" {
  type    = string
  default = "devship-eks-cluster-role"
}

variable "cluster_version" {
  type    = string
  default = "1.35"
}

variable "ecr_repositories" {
  type    = list(string)
  default = ["devship-test-repository"]
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.small"]
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 1
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "test"
    Project     = "devship"
  }
}

variable "devship_role_arn" {
  type = string
}