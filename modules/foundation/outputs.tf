output "kms_key_arn" {
  description = "ARN of the shared customer-managed CMK."
  value       = aws_kms_key.shared_cmk.arn
}

output "kms_key_id" {
  description = "Key ID of the shared CMK (used for grants and aliases)."
  value       = aws_kms_key.shared_cmk.key_id
}
