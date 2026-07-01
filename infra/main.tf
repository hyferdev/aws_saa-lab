module "foundation" {
  source = "../modules/foundation"
  tags   = merge(local.tags, { App = "shared" })
}

module "network" {
  source      = "../modules/network"
  name_prefix = local.shared_prefix
  tags        = merge(local.tags, { App = "shared" })
}

module "frontdesk" {
  source      = "../modules/frontdesk"
  name_prefix = local.app_prefix
  kms_key_arn = module.foundation.kms_key_arn

  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  tags = merge(local.tags, { App = local.app })
}

module "pipeline" {
  source      = "../modules/pipeline"
  name_prefix = local.app_prefix
  kms_key_arn = module.foundation.kms_key_arn

  asg_name              = module.frontdesk.asg_name
  alb_target_group_name = module.frontdesk.alb_target_group_name
  instance_role_name    = module.frontdesk.instance_role_name

  tags = merge(local.tags, { App = local.app })
}
