output "tfstate_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Name of the S3 bucket for tracking backend configurations"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.id
  description = "Name of the DynamoDB state locking table"
}

output "cicd_deployment_role_arn" {
  value       = aws_iam_role.cicd_deployment_role.arn
  description = "ARN of the IAM role for GitHub Actions / GitLab workflows to assume"
}
