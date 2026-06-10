# ---------------------------------------------------------------------------
# HCP Terraform OIDC: lets HCP remote workers assume a role WITHOUT static keys
# ---------------------------------------------------------------------------

data "tls_certificate" "hcp_terraform" {
  url = "https://app.terraform.io"
}

resource "aws_iam_openid_connect_provider" "hcp_terraform" {
  url             = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = [data.tls_certificate.hcp_terraform.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "hcp_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.hcp_terraform.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }

    # Scoped to this org + workspace only; run_phase wildcard covers plan and apply.
    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values   = ["organization:${var.hcp_org}:project:*:workspace:${var.hcp_workspace}:run_phase:*"]
    }
  }
}

resource "aws_iam_role" "hcp_terraform" {
  name               = "${var.project}-hcp-terraform"
  assume_role_policy = data.aws_iam_policy_document.hcp_assume.json
}

resource "aws_iam_role_policy_attachment" "hcp_terraform_admin" {
  role       = aws_iam_role.hcp_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
