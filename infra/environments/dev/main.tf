# ---------------------------------------------------------------------------
# Terraform & provider configuration
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "hello-world-dev-tfstate"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  app_name            = var.app_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------
module "security" {
  source = "../../modules/security"

  app_name             = var.app_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  vpc_cidr             = module.networking.vpc_cidr
  container_port       = var.container_port
  allowed_ingress_cidrs = var.allowed_ingress_cidrs
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  app_name    = var.app_name
  environment = var.environment
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  app_name    = var.app_name
  environment = var.environment
}

# ---------------------------------------------------------------------------
# ALB
# ---------------------------------------------------------------------------
module "alb" {
  source = "../../modules/alb"

  app_name             = var.app_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  container_port       = var.container_port
}

# ---------------------------------------------------------------------------
# ECS
# ---------------------------------------------------------------------------
module "ecs" {
  source = "../../modules/ecs"

  app_name              = var.app_name
  environment           = var.environment
  aws_region            = var.aws_region
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.security.ecs_security_group_id
  ecs_execution_role_arn = module.iam.ecs_execution_role_arn
  ecs_task_role_arn     = module.iam.ecs_task_role_arn
  container_image       = "${module.ecr.repository_url}:${var.container_image_tag}"
  target_group_arn      = module.alb.target_group_arn
  container_port        = var.container_port
  ecs_cpu               = var.ecs_cpu
  ecs_memory            = var.ecs_memory
  ecs_desired_count     = var.ecs_desired_count
  ecs_max_count         = var.ecs_max_count
}