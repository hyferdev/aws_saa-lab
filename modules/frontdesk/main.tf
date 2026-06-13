data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "instance_permissions" {
  statement {
    sid    = "FrontdeskAssetsBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      module.assets_bucket.bucket_arn,
      "${module.assets_bucket.bucket_arn}/*",
    ]
  }

  statement {
    sid    = "SharedCMKAccess"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = [var.kms_key_arn]
  }
}

module "assets_bucket" {
  source      = "../secure-bucket"
  name        = "${var.name_prefix}-assets-${data.aws_caller_identity.current.account_id}"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

module "instance_role" {
  source      = "../instance-role"
  name        = "${var.name_prefix}-instance"
  policy_json = data.aws_iam_policy_document.instance_permissions.json
  tags        = var.tags
}
