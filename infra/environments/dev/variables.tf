# ---------------------------------------------------------------------------
# Variables for the dev environment
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "app_name" {
  description = "Application name - used as a prefix for most resources"
  type        = string
  default     = "hello-world"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (ALB)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (ECS tasks)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "ecs_cpu" {
  description = "Fargate task CPU units"
  type        = string
  default     = "256"
}

variable "ecs_memory" {
  description = "Fargate task memory in MiB"
  type        = string
  default     = "512"
}

variable "ecs_desired_count" {
  description = "Desired number of Fargate tasks"
  type        = number
  default     = 1
}

variable "ecs_max_count" {
  description = "Maximum number of tasks when auto-scaling"
  type        = number
  default     = 2
}