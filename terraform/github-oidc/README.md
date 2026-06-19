# GitHub Actions OIDC deploy role

Creates an IAM role that the repo's GitHub Actions can assume via OIDC, so the
[deploy pipeline](../../.github/workflows/deploy.yml) can run `terraform` with
**no long-lived AWS access keys** stored in GitHub.

## Setup (once)

```bash
cd terraform/github-oidc
terraform init
terraform apply        # prints deploy_role_arn
```

Then in the GitHub repo, add two **Actions variables**
(Settings → Secrets and variables → Actions → Variables):

| Variable | Value |
|----------|-------|
| `AWS_DEPLOY_ROLE_ARN` | the `deploy_role_arn` output above |
| `TF_STATE_BUCKET` | your remote-state bucket (from `../bootstrap`) |

Finally, create a **`production` environment** (Settings → Environments) and add
yourself as a required reviewer, so `apply` / `destroy` runs pause for approval.

## How the trust works

The role's trust policy only allows `sts:AssumeRoleWithWebIdentity` from tokens
whose `sub` matches `repo:<owner>/<repo>:*` and `aud` is `sts.amazonaws.com`.
GitHub mints a short-lived OIDC token per run; AWS verifies it against the OIDC
provider and issues temporary credentials. Nothing long-lived is ever stored.
