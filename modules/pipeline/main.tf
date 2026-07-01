data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- Artifact bucket ---

module "artifact_bucket" {
  source      = "../secure-bucket"
  name        = "${var.name_prefix}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

# Instances need to pull the artifact revision from S3 during deployment.
resource "aws_iam_role_policy" "instance_artifact_access" {
  name   = "${var.name_prefix}-codedeploy-artifact-access"
  role   = var.instance_role_name
  policy = data.aws_iam_policy_document.instance_artifact_access.json
}

data "aws_iam_policy_document" "instance_artifact_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["${module.artifact_bucket.bucket_arn}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [module.artifact_bucket.bucket_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.kms_key_arn]
  }
}

# --- CodeStar Connection (GitHub) ---
# After apply, the connection must be manually activated in the AWS console
# (Developer Tools -> Connections -> Pending) before the pipeline can run.

resource "aws_codestarconnections_connection" "github" {
  name          = "${var.name_prefix}-github"
  provider_type = "GitHub"
  tags          = var.tags
}

# --- CodeBuild ---

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.name_prefix}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${var.name_prefix}-codebuild"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.name_prefix}-build",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.name_prefix}-build:*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:GetBucketAcl", "s3:GetBucketLocation",
    ]
    resources = [
      module.artifact_bucket.bucket_arn,
      "${module.artifact_bucket.bucket_arn}/*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_codebuild_project" "app" {
  name          = "${var.name_prefix}-build"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 10
  tags          = var.tags

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type = "CODEPIPELINE"
  }
}

# --- CodeDeploy ---

data "aws_iam_policy_document" "codedeploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "${var.name_prefix}-codedeploy"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_codedeploy_app" "app" {
  name             = var.name_prefix
  compute_platform = "Server"
  tags             = var.tags
}

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${var.name_prefix}-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  autoscaling_groups = [var.asg_name]

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = var.alb_target_group_name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  tags = var.tags
}

# --- CodePipeline ---

data "aws_iam_policy_document" "pipeline_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipeline" {
  name               = "${var.name_prefix}-pipeline"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "pipeline" {
  name   = "${var.name_prefix}-pipeline"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline_policy.json
}

data "aws_iam_policy_document" "pipeline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketVersioning",
      "s3:PutObjectAcl", "s3:PutObject",
    ]
    resources = [
      module.artifact_bucket.bucket_arn,
      "${module.artifact_bucket.bucket_arn}/*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
    resources = [aws_codebuild_project.app.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_codepipeline" "app" {
  name     = "${var.name_prefix}-pipeline"
  role_arn = aws_iam_role.pipeline.arn
  tags     = var.tags

  artifact_store {
    location = module.artifact_bucket.bucket_id
    type     = "S3"

    encryption_key {
      id   = var.kms_key_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_org}/${var.github_repo}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.app.deployment_group_name
      }
    }
  }
}
