# ───────────────────────────────────────────────────────────────────────────
# Terraform variable values – tuned for a personal / free-tier-like account
# ───────────────────────────────────────────────────────────────────────────

aws_region        = "eu-west-1"
app_name          = "hello-world"
environment       = "dev"
availability_zones = ["eu-west-1a", "eu-west-1b"]

# ── Minimal Fargate ──────────────────────────────────────────────────────
ecs_cpu           = "256"   # 0.25 vCPU – cheapest option
ecs_memory        = "512"   # minimum memory paired with 256 CPU
ecs_desired_count = 1       # single task; no cost unless you're running two
ecs_max_count     = 2       # allow a brief second task if CPU spikes