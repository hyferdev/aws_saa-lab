module "foundation" {
  source = "../modules/foundation"
  tags   = merge(local.tags, { App = "shared" })
}

module "frontdesk" {
  source      = "../modules/frontdesk"
  name_prefix = local.app_prefix
  kms_key_arn = module.foundation.kms_key_arn
  tags        = merge(local.tags, { App = local.app })
}
