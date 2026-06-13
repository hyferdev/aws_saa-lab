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
