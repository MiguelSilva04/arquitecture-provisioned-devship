output "public_ip" {
  value = aws_eip.platform.public_ip
}

output "platform_role_arn" {
  value = aws_iam_role.platform.arn
}

output "instance_id" {
  value = aws_instance.platform.id
}
