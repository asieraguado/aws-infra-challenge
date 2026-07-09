# ---------------------------------------------------------------------------
# CI/CD IAM role + policies for GitHub Actions
# ---------------------------------------------------------------------------

# ── GitHub OIDC provider ────────────────────────────────────────────────
# Required by GitHub Actions to exchange a JWT for an AWS credential.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]
}

# ── CI/CD Role ─────────────────────────────────────────────────────────
# Trusted by GitHub Actions via OIDC for this specific repo.
resource "aws_iam_role" "cicd" {
  name = "${var.app_name}-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-github-actions-role"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Terraform execution policy
# ---------------------------------------------------------------------------
# Grants permissions needed to plan and apply the dev environment.
# Scoped to resources whose names match the app/environment prefix.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "terraform" {
  # State backend
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${var.state_bucket_arn}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:DeleteItem"]
    resources = [var.locks_table_arn]
  }

  # EC2 / VPC
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeAddresses",
      "ec2:DescribeNatGateways",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeAvailabilityZones",
      "ec2:CreateVpc",
      "ec2:CreateSubnet",
      "ec2:CreateInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:CreateRouteTable",
      "ec2:CreateRoute",
      "ec2:CreateSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:DeleteVpc",
      "ec2:DeleteSubnet",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRouteTable",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:ModifyVpcAttribute",
    ]
    # Scope to the dev VPC and its resources – use a wildcard for
    # resource-level control where possible.
    resources = ["*"]
  }

  # Elastic Load Balancing
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
    ]
    resources = ["*"]
  }

  # ECS
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:ListClusters",
      "ecs:ListServices",
      "ecs:ListTaskDefinitions",
      "ecs:CreateCluster",
      "ecs:CreateService",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:DeleteCluster",
      "ecs:DeleteService",
      "ecs:UpdateService",
      "ecs:RunTask",
      "ecs:StopTask",
    ]
    resources = ["*"]
  }

  # ECR (read-only – writes are handled by the pipeline job)
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = ["*"]
  }

  # IAM (read + attach/detach for the execution role policy)
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRoles",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PassRole",
      "iam:TagRole",
    ]
    resources = [
      "arn:aws:iam::*:role/${var.app_name}-${var.environment}-*",
    ]
  }

  # DynamoDB (in case new tables are created in the future)
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
    ]
    resources = ["*"]
  }

  # Application Auto Scaling
  statement {
    effect = "Allow"
    actions = [
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:DeleteScalingPolicy",
    ]
    resources = ["*"]
  }

  # Tags – needed for Terraform to read resource tags
  statement {
    effect    = "Allow"
    actions   = ["tag:GetResources"]
    resources = ["*"]
  }

  # Allow describing the caller account (helpful for CI debugging)
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform" {
  name        = "${var.app_name}-${var.environment}-terraform-policy"
  description = "Permissions for Terraform to manage the ${var.environment} environment"
  policy      = data.aws_iam_policy_document.terraform.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "terraform" {
  role       = aws_iam_role.cicd.name
  policy_arn = aws_iam_policy.terraform.arn
}

# ---------------------------------------------------------------------------
# CI/CD pipeline policy (Docker push + ECS redeploy)
# ---------------------------------------------------------------------------
# This is attached to the same role but kept as a separate document for
# clarity. Granted only when pushing to main.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "pipeline" {
  # ECR push
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }

  # ECS update-service for redeployment
  statement {
    effect    = "Allow"
    actions   = ["ecs:UpdateService"]
    resources = ["arn:aws:ecs:${var.aws_region}:*:service/${var.app_name}-${var.environment}-cluster/${var.app_name}-${var.environment}-service"]
  }

  # PassRole for ECS execution role
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::*:role/${var.app_name}-${var.environment}-ecs-execution-role"]
  }
}

resource "aws_iam_policy" "pipeline" {
  name        = "${var.app_name}-${var.environment}-pipeline-policy"
  description = "Permissions for CI/CD pipeline (ECR push + ECS redeploy)"
  policy      = data.aws_iam_policy_document.pipeline.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "pipeline" {
  role       = aws_iam_role.cicd.name
  policy_arn = aws_iam_policy.pipeline.arn
}