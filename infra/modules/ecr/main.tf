# ---------------------------------------------------------------------------
# ECR module – container image repository
# ---------------------------------------------------------------------------

variable "app_name" {
  description = "Application name used as a prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

resource "aws_ecr_repository" "app" {
  name                 = "${var.app_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}