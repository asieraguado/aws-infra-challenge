# ---------------------------------------------------------------------------
# Terraform & provider configuration – bootstrap
# ---------------------------------------------------------------------------
# This directory is applied once to create the remote state backend (S3 bucket
# + DynamoDB table).  After it runs, the environments in infra/ can reference
# this backend for state storage and locking.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}