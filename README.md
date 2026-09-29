# moodle-aws-iac

Infrastructure-as-code for a containerized [Moodle](https://moodle.org/)
e-learning platform on AWS — a personal portfolio project to practice and
demonstrate modular Terraform, multi-environment infrastructure, container
image supply chain (build → scan → push), CI/CD automation, monitoring and
FinOps tagging end to end.

> **Note on origin:** this repository reproduces a common Moodle-on-AWS
> deployment pattern from scratch, for learning and portfolio purposes. It is
> not derived from, and contains no code, credentials or documentation from,
> any client or employer project.

## Documentation

- [**Architecture**](docs/architecture.md) — component diagram, module
  responsibilities, and the reasoning behind each design decision
- [**Deployment guide**](docs/deployment-guide.md) — first-time setup,
  deploying dev/staging/prod, promoting a change, rolling back
- [**Runbook**](docs/runbook.md) — what to check when the ECS service is
  unhealthy, cron stops running, uploads disappear, or an alarm fires
- [**Cost analysis**](docs/cost-analysis.md) — estimated monthly cost per
  environment and the single biggest lever to reduce it
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — branch naming and commit
  convention used in this repo's history

## Stack

- **Terraform**, one codebase for all environments (dev/staging/prod via
  Terraform workspaces + `vars/<environment>.tfvars`) — modules:
  `network`, `alb`, `ecs`, `ecr`, `rds`, `efs`, `monitoring`, `cdn`, `dns`,
  `tags`, under [`terraform/modules`](terraform/modules)
- **AWS**: VPC (NAT per AZ by default), ALB (optional HTTPS listener),
  ECS Fargate (app + scheduled cron task), ECR, RDS for MySQL, EFS,
  CloudFront (optional), Route53 (optional), WAFv2 (optional, managed
  rules + rate limiting), CloudWatch Alarms/Dashboard, SNS, Secrets
  Manager, EventBridge, IAM
- **Docker**: multi-stage build (`docker/Dockerfile`) — a throwaway stage
  fetches and unpacks Moodle, the runtime stage ships only `php:8.2-apache`
  plus the application code, with no build tools in the final image
- **GitHub Actions**: one pipeline for `terraform fmt`/`validate`/`plan`/
  `apply`, environment-aware (workspace + `-var-file` selected via a
  workflow input), OIDC auth to AWS, manual approval gate before `apply`;
  a separate pipeline builds, vulnerability-scans (Trivy), and pushes the
  Moodle image, then forces a new ECS deployment
- **FinOps**: every resource carries the same `Project`/`Environment`/
  `ManagedBy`/`CostCenter`/`Owner` tags from a single `tags` module

## Quick start

```bash
cd docker && docker build -t <your-ecr-repo>:latest . && docker push <your-ecr-repo>:latest

cd ../terraform/environments/app
terraform init
terraform workspace new dev   # first time only
terraform workspace select dev
terraform plan  -var-file="vars/dev.tfvars"
terraform apply -var-file="vars/dev.tfvars"
```

Full walkthrough, including staging/prod and promoting a change between
them, in [docs/deployment-guide.md](docs/deployment-guide.md).

## Repository layout

```
.
├── docker/                    # Dockerfile, entrypoint, minimal config.php
├── docs/                      # architecture, deployment, runbook, cost analysis
├── terraform/
│   ├── modules/
│   │   ├── network/           # VPC, public/private subnets, NAT, routing
│   │   ├── alb/                # Application Load Balancer + target group
│   │   ├── ecs/                 # Fargate cluster, app + cron task definitions, service
│   │   ├── ecr/                 # Container registry + lifecycle policy
│   │   ├── rds/                 # MySQL instance + Secrets Manager credentials
│   │   ├── efs/                 # Shared filesystem for moodledata/
│   │   ├── monitoring/          # CloudWatch alarms, dashboard, SNS topic
│   │   ├── cdn/                  # Optional CloudFront distribution
│   │   ├── dns/                  # Optional Route53 records
│   │   └── tags/                  # Standard FinOps tag set
│   └── environments/
│       └── app/                    # One codebase, all environments (see vars/*.tfvars)
└── .github/workflows/
    ├── terraform.yml           # fmt / validate / plan / manual apply, per environment
    └── docker-build.yml        # build → scan → push → force new deployment
```

## What I'd still change for a heavier production load

- **A real ACM certificate + domain**, to actually turn on the HTTPS
  listener (`acm_certificate_arn`) and Route53 (`domain_name`) that
  already exist as opt-in variables — there's no code left to write
  here, just a domain to register
- **Remote Terraform state backend** (S3 + DynamoDB lock table) — currently
  local state per workspace; scaffolded, commented out, in
  [`terraform/environments/app/versions.tf`](terraform/environments/app/versions.tf)
- **A cache behavior for static theme assets** on CloudFront, once real
  traffic patterns justify the added complexity over the current
  no-cache-anywhere default
- **tflint / checkov / tfsec in CI** — static analysis and security
  scanning of the Terraform itself, before `plan` ever runs
- **Automated tests** — none exist yet, at any level (module, integration)
