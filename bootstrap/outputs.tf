output "hcp_role_arn" {
  description = "Add to HCP workspace env vars as TFC_AWS_RUN_ROLE_ARN."
  value       = aws_iam_role.hcp_terraform.arn
}
