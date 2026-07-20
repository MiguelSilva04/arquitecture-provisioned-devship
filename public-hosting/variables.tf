variable "region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "devship"
  }
}

variable "admin_cidr" {
  type        = string
  description = "CIDR allowed to SSH (port 22) into the public host, e.g. \"203.0.113.4/32\""
}

variable "ssh_public_key" {
  type        = string
  description = "Public key (OpenSSH format) installed on the EC2 instance for SSH access"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "client_role_prefix" {
  type        = string
  description = "Prefix of client IAM roles the platform is allowed to assume (sts:AssumeRole)"
  default     = "AccessPlatformDevShip"
}
