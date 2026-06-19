# Remote state bootstrap

Creates the S3 bucket (versioned + encrypted + private) and DynamoDB lock table
that back the main Terraform configuration's remote state.

Run this **once**, with local state, before using the remote backend in `../`.

```bash
cd terraform/bootstrap
terraform init
terraform apply -var state_bucket_name=student-records-tfstate-<yourname>
```

Then wire the main config to the backend:

```bash
cd ..
cp backend.hcl.example backend.hcl     # set bucket name from the output above
terraform init -backend-config=backend.hcl   # migrates local state to S3
```

## Why remote state

- **Shared + durable:** state lives in S3 (versioned), not on one laptop.
- **Locking:** the DynamoDB table prevents two applies from racing and corrupting state.
- **Encrypted:** state can contain sensitive values, so the bucket enforces SSE and blocks all public access.

Cost is effectively **$0** at this scale (a few KB in S3, pay-per-request DynamoDB).
