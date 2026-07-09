# ---------------------------------------------------------------------------
# Outputs – bootstrap IAM
# ---------------------------------------------------------------------------

output "cicd_role_arn" {
  description = "ARN of the CI/CD role for GitHub Actions. Use as the AWS_ROLE_ARN secret."
  value       = aws_iam_role.cicd.arn
}

output "cicd_role_name" {
  description = "Name of the CI/CD role"
  value       = aws_iam_role.cicd.name
}

output "terraform_policy_arn" {
  description = "ARN of the Terraform execution policy"
  value       = aws_iam_policy.terraform.arn
}

output "pipeline_policy_arn" {
  description = "ARN of the CI/CD pipeline policy"
  value       = aws_iam_policy.pipeline.arn
}