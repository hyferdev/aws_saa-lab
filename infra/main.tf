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

  ecr_repository_url = module.frontdesk.ecr_repository_url
  ecr_repository_arn = module.frontdesk.ecr_repository_arn
  ecs_cluster_name   = module.frontdesk.ecs_cluster_name
  ecs_service_name   = module.frontdesk.ecs_service_name

  tags = merge(local.tags, { App = local.app })
}
