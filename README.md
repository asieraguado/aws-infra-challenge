# aws-infra-challenge

A small Node.js app ("Hello world" on port 3000 with a `/health` endpoint) containerised with Docker and deployed to AWS ECS Fargate behind an Application Load Balancer, all managed via Terraform with a GitHub Actions CI/CD pipeline.

---

## Design decisions

### Runtime: why ECS Fargate and not EKS or plain VMs

We chose **ECS Fargate** because it is the most cost-effective option for a personal AWS account with a micro-budget:

| Runtime | Monthly cost (always-on, minimal spec) | Notes |
|---|---|---|
| **ECS Fargate** | ~$7–10 | No cluster management overhead; pay per task per second. 256 CPU / 512 MB is the smallest combo. |
| **EKS** | ~$73 | Cluster control plane costs $0.10/hour regardless of usage — too expensive for this scope. |
| **EC2 (VM)** | ~$8–15 | Cheapest t4g.nano is comparable, but you own the OS patching, capacity planning, and have no built-in rolling updates. |

**Trade-offs:**
- **Cost at scale** – Fargate has a per-task markup (~20%) over equivalent EC2, so high-traffic workloads would be cheaper on EC2 or spot instances.
- **Cloud portability** – ECS is AWS-native. If multi-cloud portability matters, EKS (Kubernetes) is the better choice, but the control-plane cost was prohibitive here.

### Networking and security

```
Internet
   │
   ▼
┌────────────────┐
│  ALB           │  ← public subnets (2 AZs)
│  port 80       │
└────────┬───────┘
         │ only traffic from ALB SG
         ▼
┌────────────────┐
│  ECS Fargate   │  ← private subnets (2 AZs), no public IPs
│  port 3000     │
└────────────────┘
```

**Principles applied:**
1. **Compute in private subnets** – ECS tasks have `assign_public_ip = false`. They cannot be reached directly from the internet.
2. **Security-group-based isolation** – The ECS security group uses a `referenced_security_group_id` pointing to the ALB SG. Only the ALB can talk to the containers. No CIDR-based ingress on the ECS side.
3. **ALB egress locked down** – The ALB's egress rule restricts outbound traffic to only the VPC CIDR on the container port.
4. **Least-privilege IAM** – The ECS task role has **zero permissions** (the app makes no AWS API calls). The execution role only gets the managed `AmazonECSTaskExecutionRolePolicy` (ECR pull + CloudWatch logs).
5. **Single NAT Gateway** – Cost optimisation. In production you'd want one per AZ for HA.
6. **Public subnets only for the ALB** – No other resource lives in a public subnet.

### CI/CD pipeline

The pipeline is structured for **trunk-based development**. Every push triggers two parallel jobs:

```
Push to any branch
├── Docker build (app/)
└── Terraform plan (infra/environments/dev)

Push to main (the above, plus)
├── Docker push to ECR
│   └── Force ECS redeployment
└── Terraform apply
```

**Current approach and known limitations:**

- **Parallel app + infra jobs** – Both run at the same time for simplicity. This works for a prototype but isn't standard practice. In a real team you'd typically separate them: the app pipeline deploys the app, the infra pipeline manages infrastructure changes independently. Merging them means a failed `terraform apply` can block an app deployment and vice versa.
- **Single environment** – Only `dev` exists today, but the directory structure (`infra/environments/`) supports adding `staging` and `prod` by copying the pattern and swapping the backend key.
- **Trigger model** – Push-based (automatic on main). No manual approval gates yet, which you'd want for production.

### State management

| Component | Backend | Notes |
|---|---|---|
| **`infra/environments/dev`** | S3 (`hello-world-dev-tfstate` / `dev/terraform.tfstate`) | Native locking with `use_lockfile` without DynamoDB. |
| **`bootstrap/s3`** | **Local** (applied once) | Creates the S3 bucket used by the dev environment. |
| **`bootstrap/iam`** | **Local** (applied once) | Creates the GitHub Actions OIDC provider, CI/CD role, Terraform policy, and pipeline policy. |

The bootstrap directories intentionally use local state – they provision the resources that everything else depends on. In a team setting, the bootstrap state should also be migrated to an S3 backend (possibly a separate, dedicated bucket) so it benefits from locking and remote access.

---

## Repository structure

```
.
├── app/                          # Node.js application
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── infra/                        # Infrastructure as Code (Terraform)
│   ├── bootstrap/
│   │   ├── s3/                   # S3 bucket (state backend)
│   │   └── iam/                  # GitHub OIDC provider + CI/CD role
│   ├── environments/
│   │   └── dev/                  # Dev environment root module
│   │       ├── main.tf           # Module wiring + S3 backend
│   │       ├── variables.tf      # Environment variables
│   │       ├── terraform.tfvars  # Dev-specific values
│   │       └── outputs.tf
│   └── modules/                   # Shared Terraform modules
│       ├── networking/            # VPC, subnets, IGW, NAT GW, route tables
│       ├── security/              # ALB + ECS security groups
│       ├── iam/                   # ECS execution + task roles
│       ├── ecr/                   # Container image repository
│       ├── alb/                   # ALB, target group, listener
│       └── ecs/                   # Fargate cluster, service, task definition, auto-scaling
├── .github/workflows/
│   └── ci-cd.yml                 # GitHub Actions pipeline
├── AGENTS.md                     # AI agent instructions
├── CHALLENGE.md                  # Original challenge brief
└── README.md                     # This file
```

---

## How to provision

### Prerequisites

- Terraform >= 1.5
- AWS CLI configured with credentials for your account
- A GitHub repository with OIDC configured (see bootstrap/iam)

### Step 1 – Bootstrap the S3 backend

```bash
cd infra/bootstrap/s3
terraform init
terraform apply
```

This creates:
- `hello-world-dev-tfstate` S3 bucket (versioned, encrypted, public access blocked)

### Step 2 – Bootstrap the CI/CD IAM role

```bash
cd infra/bootstrap/iam
terraform init
terraform apply \
  -var="github_org=asieraguado" \
  -var="github_repo=aws-infra-challenge" \
  -var="state_bucket_arn=arn:aws:s3:::hello-world-dev-tfstate" \
```

This creates:
- GitHub OIDC provider (`token.actions.githubusercontent.com`)
- `hello-world-dev-github-actions-role` IAM role
- `hello-world-dev-terraform-policy` (full Terraform permissions for the dev environment)
- `hello-world-dev-pipeline-policy` (ECR push + ECS redeploy)

Set the output `cicd_role_arn` as the `AWS_ROLE_ARN` secret in your GitHub repo.

### Step 3 – Apply the dev environment

```bash
cd infra/environments/dev
terraform init
terraform plan
terraform apply
```

This provisions (or updates) the full stack: VPC, subnets, NAT Gateway, security groups, IAM roles, ECR repository, ALB, ECS cluster, and Fargate service.

The app will be available at the ALB DNS name shown in the Terraform outputs:
```
alb_dns_name = hello-world-dev-alb-XXXXXX.eu-west-1.elb.amazonaws.com
```

---

## CI/CD

Every push runs:

1. **Docker build** – Builds and tags the image as `:latest`, `:main` (on main), `:${{ github.sha }}`.
2. **Terraform plan** – Validates formatting, runs `init`, `validate`, and `plan`.

On push to `main`, additionally:

3. **Docker push** – Pushes the image to ECR.
4. **ECS redeploy** – Forces a new deployment with the updated image.
5. **Terraform apply** – Applies any infrastructure changes.

To configure the pipeline, add `AWS_ROLE_ARN` as a repository secret in GitHub pointing to the CI/CD role ARN from step 2.

---

## What's next / improvements

| Area | What's missing | Priority |
|---|---|---|
| **HTTPS** | Add ACM certificate + Route53 alias for the ALB. | High |
| **Observability** | Structured JSON logging, CloudWatch dashboard widget, 5xx alarm. | Medium |
| **State migration** | Move `bootstrap/` states to S3 backend. | Medium |
| **Multi-env** | Wire up `staging` / `prod` environments with separate tfvars and backend keys. | Medium |
| **Pipeline separation** | Split app and infra into independent workflows. | Low (for now) |
| **Manual approval** | Add a manual gate before `terraform apply` on production. | Low (for now) |
| **Cost** | Use Fargate spot for non-production, review NAT Gateway cost. | Low |

---

## AI workflow

This project was built with heavy use of AI. The `AGENTS.md` configuration that guided the AI is committed to the repo. See `AGENTS.md` for the agent persona and rules used during development. 
- Agent: GitHub Copilot (local agent).
- Model: DeepSeek V4 Flash.
