# ---------------------------------------------------------------------------
# Security groups
# ---------------------------------------------------------------------------

# ── ALB Security Group ──────────────────────────────────────────────────
# Allows HTTP(S) from the internet; egress to the VPC CIDR only.
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.environment}-alb-sg"
  description = "Controls traffic to the ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.app_name}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# Ingress: HTTP from allowed CIDRs — one rule per CIDR
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP from ${each.value}"
}

# Egress: only to the VPC (reach the containers)
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = var.container_port
  to_port           = var.container_port
  ip_protocol       = "tcp"
  description       = "Traffic to ECS tasks on container port"
}

# ── ECS Security Group ──────────────────────────────────────────────────
# Only accepts traffic from the ALB security group.
resource "aws_security_group" "ecs" {
  name        = "${var.app_name}-${var.environment}-ecs-sg"
  description = "Controls traffic to ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.app_name}-${var.environment}-ecs-sg"
    Environment = var.environment
  }
}

# Ingress: only from the ALB security group
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  description                  = "Allow traffic only from the ALB"
}

# Egress: allow all outbound so tasks can pull images and make API calls
resource "aws_vpc_security_group_egress_rule" "ecs_egress" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all traffic
  description       = "Allow all outbound (ECR, API calls, etc.)"
}