# ---------------------------------------------------------------------------
# Variables – bootstrap IAM
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "app_name" {
  description = "Application name – used as a prefix for policies"
  type        = string
  default     = "hello-world"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "github_org" {
  description = "GitHub organisation or username that owns the repo"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  type        = string
}

variable "locks_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  type        = string
}