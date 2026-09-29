# Cost analysis (estimate)

Ballpark **monthly** figures for `us-east-1`, On-Demand pricing, meant to
show cost-awareness rather than as an exact bill — actual cost depends
on real usage, and this project has never been left running continuously
in a personal AWS account.

## Dev (`enable_cdn = false`, single AZ, 1 ECS task)

| Resource | Estimate |
|---|---|
| NAT Gateway (1x) | ~$32 + data processing |
| ALB | ~$16 + LCU usage |
| ECS Fargate (1 task, 0.5 vCPU / 1 GB, ~730h) | ~$15 |
| ECS Fargate cron task (256/512, ~1 min/run, 43,200 runs/mo) | ~$3–5 |
| RDS `db.t4g.micro`, single-AZ, 20 GB | ~$13 |
| EFS (low usage, <5 GB) | ~$1–2 |
| CloudWatch (alarms + dashboard + logs) | ~$2–3 |
| ECR storage | <$1 |
| **Total** | **~$85–90/month** |

## Staging (`enable_cdn = true`, otherwise same shape as dev)

Adds CloudFront (~$1–5/month at this traffic level, mostly request-based)
and an SNS email subscription (free tier). **~$90–100/month.**

## Prod (`enable_cdn = true`, Multi-AZ RDS, 2 ECS tasks)

| Change vs. staging | Delta |
|---|---|
| RDS Multi-AZ (2x `db.t4g.small` effectively) | +~$25–30 |
| 2nd ECS task | +~$15 |
| `deletion_protection = true` | $0 (no cost, just a safety switch) |
| **Total** | **~$130–150/month** |

## The single biggest lever

The NAT Gateway is the largest fixed cost relative to how little this
project actually uses it. The real client project this is inspired by
solved that with a self-managed NAT **instance** instead of the managed
NAT Gateway (cheaper at low/moderate traffic, more ops overhead) — a
deliberate trade-off documented as a possible future change here too,
not implemented by default since it adds an EC2 instance to patch and
monitor for a portfolio project that doesn't need the savings badly
enough to justify that.

## What this analysis intentionally leaves out

Data transfer costs are traffic-dependent and impossible to estimate
honestly without real usage; CloudFront/data-out figures above assume
low, portfolio-review-level traffic, not production load.
