data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- Artifact bucket ---

module "artifact_bucket" {
  source      = "../secure-bucket"
  name        = "${var.name_prefix}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

# --- CodeStar Connection (GitHub) ---
# After first apply, activate the connection in the console:
# Developer Tools -> Connections -> Pending -> Update pending connection.

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
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.name_prefix}-build",
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.name_prefix}-build:*",
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

  # Auth token request must be against *.
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Image push scoped to the specific repository.
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_codebuild_project" "app" {
  name          = "${var.name_prefix}-build"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 15
  tags          = var.tags

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPO_URI"
      value = var.ecr_repository_url
    }
  }

  source {
    type = "CODEPIPELINE"
  }
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
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:TagResource",
      "ecs:UpdateService",
    ]
    resources = ["*"]
  }

  # Required so the pipeline can pass execution and task roles to ECS.
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
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
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
