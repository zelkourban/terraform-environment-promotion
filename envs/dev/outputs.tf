output "bucket_id" {
  description = "Name of the application bucket."
  value       = module.app_stack.bucket_id
}

output "instance_id" {
  description = "ID of the application instance."
  value       = module.app_stack.instance_id
}
