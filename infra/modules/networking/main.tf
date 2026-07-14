# ---------------------------------------------------------------------------
# Networking module – VPC, subnets, IGW, NAT Gateway, route tables
# ---------------------------------------------------------------------------

variable "app_name" {
  description = "Application name used as a prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.app_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Public subnets – ALB lives here
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-${var.environment}-public-${count.index + 1}"
    Tier        = "public"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Private subnets – ECS Fargate tasks live here
# ---------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.app_name}-${var.environment}-private-${count.index + 1}"
    Tier        = "private"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.app_name}-${var.environment}-igw"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Elastic IP – for the NAT Gateway
# ---------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.app_name}-${var.environment}-nat-eip"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# NAT Gateway – single AZ to keep costs low
# ---------------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.app_name}-${var.environment}-nat"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Multi-AZ NAT Gateways (commented out – uncomment for HA across AZs)
# ---------------------------------------------------------------------------
# resource "aws_eip" "nat" {
#   count = length(var.availability_zones)
#   domain = "vpc"
#
#   tags = {
#     Name        = "${var.app_name}-${var.environment}-nat-eip-${count.index + 1}"
#     Environment = var.environment
#   }
# }
#
# resource "aws_nat_gateway" "main" {
#   count          = length(var.availability_zones)
#   allocation_id  = aws_eip.nat[count.index].id
#   subnet_id      = aws_subnet.public[count.index].id
#   depends_on     = [aws_internet_gateway.main]
#
#   tags = {
#     Name        = "${var.app_name}-${var.environment}-nat-${count.index + 1}"
#     Environment = var.environment
#   }
# }

# ---------------------------------------------------------------------------
# Route tables
# ---------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-private-rt"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Per-AZ private route tables for multi-AZ NAT (commented out)
# ---------------------------------------------------------------------------
# resource "aws_route_table" "private" {
#   count  = length(var.availability_zones)
#   vpc_id = aws_vpc.main.id
#
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.main[count.index].id
#   }
#
#   tags = {
#     Name        = "${var.app_name}-${var.environment}-private-rt-${count.index + 1}"
#     Environment = var.environment
#   }
# }
#
# resource "aws_route_table_association" "private" {
#   count          = length(var.availability_zones)
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private[count.index].id
# }

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}