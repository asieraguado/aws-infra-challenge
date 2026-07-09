# ---------------------------------------------------------------------------
# Variables – bootstrap
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to create the backend in"
  type        = string
  default     = "eu-west-1"
}

variable "app_name" {
  description = "Application name – used as a prefix for the bucket / table"
  type        = string
  default     = "hello-world"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}