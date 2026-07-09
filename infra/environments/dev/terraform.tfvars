# ───────────────────────────────────────────────────────────────────────────
# Dev environment variable values
# ───────────────────────────────────────────────────────────────────────────

aws_region         = "eu-west-1"
app_name           = "hello-world"
environment        = "dev"
availability_zones = ["eu-west-1a", "eu-west-1b"]

ecs_cpu           = "256"
ecs_memory        = "512"
ecs_desired_count = 1
ecs_max_count     = 2