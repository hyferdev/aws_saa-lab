output "shared_kms_key_arn" {
  description = "ARN of the shared CMK."
  value       = module.foundation.kms_key_arn
}

output "vpc_id" {
  description = "ID of the shared VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ordered a, b)."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (ordered a, b)."
  value       = module.network.private_subnet_ids
}

output "frontdesk_alb_dns" {
  description = "Public DNS of the FrontDesk ALB."
  value       = module.frontdesk.alb_dns_name
}

output "frontdesk_assets_bucket" {
  description = "Name of the frontdesk assets bucket."
  value       = module.frontdesk.assets_bucket_id
}

output "frontdesk_ecr_repository_url" {
  description = "ECR repository URI for the frontdesk image."
  value       = module.frontdesk.ecr_repository_url
}

output "frontdesk_ecs_cluster" {
  description = "Name of the frontdesk ECS cluster."
  value       = module.frontdesk.ecs_cluster_name
}
