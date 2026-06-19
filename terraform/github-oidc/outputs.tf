output "deploy_role_arn" {
  description = "Set this as the AWS_DEPLOY_ROLE_ARN variable in the GitHub repo (Settings > Secrets and variables > Actions > Variables)."
  value       = aws_iam_role.deploy.arn
}
