output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of the instance."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP, when assign_public_ip is set. Null otherwise."
  value       = var.assign_public_ip ? aws_instance.this.public_ip : null
}

output "role_arn" {
  description = "ARN of the instance role."
  value       = aws_iam_role.this.arn
}

output "security_group_id" {
  description = "ID of the instance security group."
  value       = aws_security_group.this.id
}
