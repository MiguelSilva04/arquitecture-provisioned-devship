variable "tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "devship"
  }
}

variable "vpc" {
  type = object({
    name                    = string
    cidr_block              = string
    internet_gateway_name   = string
    public_route_table_name = string
    public_subnets = list(object({
      name                    = string
      cidr_block              = string
      availability_zone       = string
      map_public_ip_on_launch = bool
    }))
  })
  # teste executado em us-east-1
  default = {
    name                    = "devship-tf-vpc"
    cidr_block              = "10.0.0.0/24"
    internet_gateway_name   = "devship-tf-igw"
    public_route_table_name = "devship-tf-public-rt"
    public_subnets = [
      {
      name                    = "devship-tf-public-subnet-us-east-1a"
      cidr_block              = "10.0.0.0/26"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
      },
      {
        name                    = "devship-tf-public-subnet-us-east-1b"
        cidr_block              = "10.0.0.64/26"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = true
    }]
  }
}
