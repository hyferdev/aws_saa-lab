data "aws_caller_identity" "current" {}

resource "aws_kms_key" "shared_cmk" {
  description             = "Shared CMK for saa platform (S3 + EBS)"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = var.tags
}

resource "aws_kms_alias" "shared_cmk" {
  name          = "alias/saa-shared-cmk"
  target_key_id = aws_kms_key.shared_cmk.key_id
}

resource "aws_ebs_encryption_by_default" "region_default" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "region_default" {
  key_arn = aws_kms_key.shared_cmk.arn
}

# ASG service-linked role needs this grant to launch instances with encrypted EBS.
resource "aws_kms_grant" "asg" {
  name              = "asg-ebs-encryption"
  key_id            = aws_kms_key.shared_cmk.key_id
  grantee_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "ReEncryptTo",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "DescribeKey",
    "CreateGrant",
  ]
}
