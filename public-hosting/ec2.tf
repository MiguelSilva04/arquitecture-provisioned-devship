data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_key_pair" "platform" {
  key_name   = "devship-platform-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "platform" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = module.networking.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.public_host.id]
  iam_instance_profile        = aws_iam_instance_profile.platform.name
  key_name                    = aws_key_pair.platform.key_name
  associate_public_ip_address = true

  # sem hop_limit=2 os contentores docker não conseguem alcançar o IMDS (um hop extra pela bridge network)
  metadata_options {
    http_tokens                = "required"
    http_put_response_hop_limit = 2
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    dnf install -y docker git
    systemctl enable --now docker
    usermod -aG docker ec2-user
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
      -o /usr/libexec/docker/cli-plugins/docker-compose
    chmod +x /usr/libexec/docker/cli-plugins/docker-compose
  EOF

  tags = { Name = "devship-platform" }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

resource "aws_eip" "platform" {
  instance = aws_instance.platform.id
  domain   = "vpc"

  tags = { Name = "devship-platform-eip" }
}
