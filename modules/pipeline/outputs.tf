output "pipeline_name" {
  description = "Name of the CodePipeline."
  value       = aws_codepipeline.app.name
}

output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application."
  value       = aws_codedeploy_app.app.name
}

output "codestar_connection_arn" {
  description = "ARN of the CodeStar GitHub connection — must be manually activated in the console before the pipeline can run."
  value       = aws_codestarconnections_connection.github.arn
}

output "artifact_bucket_id" {
  description = "Name of the S3 bucket storing pipeline artifacts."
  value       = module.artifact_bucket.bucket_id
}
