

the agile monkeys.
TECHNICAL VALIDATION

Senior DevOps / Platform  Engineer

## The challenge

Take the small Node server in this repo and get it running in the cloud through a
CI/CD pipeline. The app has two endpoints: `/` returns “Hello world”, and `/health`
returns a 200 so a load balancer or cluster can check it. Copy it into your own repo
and make it yours.
This mirrors the real work. You’d own the infrastructure, the pipelines, and the
deployments that keep a live product healthy in production.

## What we’d like to see

- Deploy with an Infrastructure as Code tool. We work in Terraform, so that’s our
preference. If you’re stronger in Pulumi or another IaC tool, use it and tell us
why.
- Target AWS or Azure. Our platform is moving onto both, and AWS experience is
especially valuable to us, so it’s a good place to show your depth. (Skip GCP for
this one.)
- Containerize the app with Docker. The runtime is your call: ECS, AKS, plain
VMs, Kubernetes. Pick what fits and be ready to defend the choice.
- Use GitHub Actions for CI/CD. It’s what we run internally.
- Put a load balancer in front of the app as the entry point. This is where we
want to see your thinking on networking and security.
- The pipeline should build and deploy, manually or automatically. Your call on
the trigger model.

## A note on AI

AI is part of how we work every day. Use it freely here; we do too. Just own
every line you send us.
We’re an AI-first team, so we care about how you work with AI as much as
the result. Commit your AI setup to the repo and include whatever helped
you build: prompts, plans, and configuration. For example: .claude config,
CLAUDE.md / AGENTS.md files, a directory of tasks or plans in markdown, and
any skills, agents, or hooks you set up. Show us your workflow.

## How it works

You won’t wire up everything, and that’s fine. Pick a slice you can stand behind and
do it well, then tell us what you left out. We care more about your decisions than
your coverage. We’re looking at the breadth of DevOps: Linux, cloud, containers,
GitOps, networking, SecOps, CI/CD, observability. High-level fluency is fine.
We review what you send first: the repo, the config, and the reasoning behind it, AI
included. So make the why easy to find. You won’t need to wire up metrics and
logging in the deployed app, but a note on how you’d approach it helps.
If the work is strong, we pair. Only then do we set up a conversation, go through
your setup together, and talk through a few real situations. No whiteboard puzzles,
no trick questions. And if you want to show off, go for it: Kubernetes, real
observability, a clean security posture, sensible secrets handling. Anything you’re
proud of.

## Send us the repo

Push your code to a repo and send us the link. Make sure it includes four things:
- The infra and the pipeline. Your IaC config and the app’s CI, in the same repo
if you like. Your commit history is part of the story, so let it show how you got
there.
- A README. How to provision, build and deploy, so we can follow it without
asking you. Include a link to the running app; to avoid sitting on cloud costs you
don’t need to keep it live the whole time, just be ready to bring it up when we
ask.
- Your AI session. The record of how you worked with AI, whatever your tools
produce: your .claude config, prompts, plans, a chat export. We want to see
how you used it, not whether you did.
- Walk us through it. An async walkthrough of how you approached it: why you
chose the runtime, how the networking and security are laid out, the
cross-cloud portability trade-off, and what you’d improve next. Any format, a
Loom, a video, a deck, a doc. Keep it tight: under ten minutes if it’s a video,
under fifteen slides if it’s a deck.

An initiative by The Agile Monkeys
