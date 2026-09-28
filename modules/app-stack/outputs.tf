output "bucket_id" {
  description = "Name of the application bucket."
  value       = module.bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the application bucket."
  value       = module.bucket.bucket_arn
}

output "kms_key_arn" {
  description = "ARN of the CMK encrypting the application bucket."
  value       = module.bucket.kms_key_arn
}

output "instance_id" {
  description = "ID of the application instance."
  value       = module.compute.instance_id
}

output "instance_private_ip" {
  description = "Private IP of the application instance."
  value       = module.compute.private_ip
}

output "instance_public_ip" {
  description = "Public IP of the application instance, when assign_public_ip is set."
  value       = module.compute.public_ip
}
