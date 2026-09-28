output "bucket_id" {
  description = "Name of the application bucket."
  value       = module.app_stack.bucket_id
}

output "instance_id" {
  description = "ID of the application instance."
  value       = module.app_stack.instance_id
}

output "instance_public_ip" {
  description = "Public IP, when assign_public_ip is set. Null in a private-subnet deployment."
  value       = module.app_stack.instance_public_ip
}
