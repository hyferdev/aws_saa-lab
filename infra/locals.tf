locals {
  org           = "saa"
  app           = "frontdesk"
  shared_prefix = "${local.org}-shared"
  app_prefix    = "${local.org}-${local.app}"

  tags = {
    Project   = local.org
    ManagedBy = "terraform"
    Env       = "sandbox"
  }
}
