output "assets_bucket_id" {
  description = "Name of the frontdesk assets S3 bucket."
  value       = module.assets_bucket.bucket_id
}

output "assets_bucket_arn" {
  description = "ARN of the frontdesk assets S3 bucket."
  value       = module.assets_bucket.bucket_arn
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.app.dns_name
}

output "alb_arn" {
  description = "ARN of the application load balancer."
  value       = aws_lb.app.arn
}

output "ecr_repository_url" {
  description = "Full URI of the ECR repository (without tag)."
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository."
  value       = module.ecr.repository_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = var.name_prefix
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = var.name_prefix
}
