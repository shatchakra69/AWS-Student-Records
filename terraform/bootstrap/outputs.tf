output "state_bucket" {
  description = "Name of the S3 state bucket. Put this in ../backend.hcl."
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "Name of the DynamoDB lock table. Put this in ../backend.hcl."
  value       = aws_dynamodb_table.locks.name
}
