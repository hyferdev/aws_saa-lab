data "aws_caller_identity" "current" {}

module "assets_bucket" {
  source      = "../secure-bucket"
  name        = "${var.name_prefix}-assets-${data.aws_caller_identity.current.account_id}"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

module "ecr" {
  source      = "../ecr"
  name        = var.name_prefix
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}
