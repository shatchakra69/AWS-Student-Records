# Remote state backend: S3 for storage, DynamoDB for state locking.
#
# Uses PARTIAL configuration so the bucket/table aren't hardcoded in the repo.
# One-time setup:
#   1. cd bootstrap && terraform init && terraform apply   (creates bucket + lock table)
#   2. cp backend.hcl.example backend.hcl                  (fill in the bucket name)
#   3. terraform init -backend-config=backend.hcl          (migrates state to S3)
#
# CI runs `terraform init -backend=false`, so it never touches the live backend.
terraform {
  backend "s3" {}
}
