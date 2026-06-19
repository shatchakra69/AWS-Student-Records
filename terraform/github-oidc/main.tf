# One-time setup that lets GitHub Actions deploy via OIDC, with NO long-lived
# AWS access keys stored in GitHub. Run once:
#   cd terraform/github-oidc && terraform init && terraform apply
# Then set the `deploy_role_arn` output as the AWS_DEPLOY_ROLE_ARN repo variable.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# GitHub Actions OIDC identity provider (one per AWS account).
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Trust policy: only workflows from this repo may assume the role.
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "github-actions-student-records"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# PowerUserAccess covers the stack's resources; the inline policy below adds the
# IAM actions the stack needs (it creates an EC2 instance role and profile).
# Replace with a least-privilege policy for production.
resource "aws_iam_role_policy_attachment" "power" {
  role       = aws_iam_role.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "iam" {
  statement {
    sid = "ManageStackIamRole"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:PassRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile", "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile", "iam:TagRole",
      "iam:TagInstanceProfile", "iam:ListInstanceProfilesForRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "iam" {
  name   = "manage-stack-iam"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.iam.json
}
