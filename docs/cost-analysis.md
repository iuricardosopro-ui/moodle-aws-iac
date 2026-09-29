# Cost analysis

## Methodology — and a correction

An earlier version of this document estimated monthly costs from
general knowledge of typical AWS pricing, without checking the actual
current rates. That was a mistake: an estimate that *looks* precise
(specific dollar figures) but isn't actually sourced is worse than no
estimate at all, because it invites treating it as more reliable than
it is.

The figures below were checked against AWS's own pricing pages (and,
where the page didn't render a rate directly, a third-party aggregator
that quotes AWS's published rate, cross-checked) on 2026-09-29, for
`us-east-1`, On-Demand pricing:

- NAT Gateway: **$0.045/hour** + **$0.045/GB** data processed — [AWS VPC pricing](https://aws.amazon.com/vpc/pricing/)
- Fargate (Linux/x86): **$0.04048/vCPU-hour**, **$0.004445/GB-hour** — [AWS Fargate pricing](https://aws.amazon.com/fargate/pricing/)
- RDS `db.t4g.micro` MySQL: **~$0.016/hour** (~$12/month) — [Bytebase RDS pricing](https://www.bytebase.com/dbcost/rds/instance/db.t4g.micro/), quoting AWS's published rate
- AWS WAF: **$5/month per Web ACL** + **$1/month per rule** + **$0.60 per million requests** — [AWS WAF pricing](https://aws.amazon.com/waf/pricing/)
- EFS Standard: **$0.30/GB-month**; EFS Infrequent Access: **$0.016/GB-month** — [Vantage EFS pricing guide](https://www.vantage.sh/blog/amazon-efs-pricing), quoting AWS's published rate
- ALB: **$0.0225/hour** + **$0.008/LCU-hour** — long-standing, stable published rate, not re-verified in this pass
- RDS General Purpose (gp2) storage: **~$0.115/GB-month** — long-standing, stable published rate, not re-verified in this pass
- CloudFront: **~$0.085/GB** for the first 10 TB/month (US/Europe) — long-standing, stable published rate, not re-verified in this pass

Anything marked "not re-verified in this pass" is a rate that has been
stable for years and matches what every pricing aggregator currently
lists — worth a final check against the AWS Pricing Calculator before
treating this document as authoritative, but not something that moved
meaningfully in the last search.

## Dev — `vars/dev.tfvars`

`single_nat_gateway = true`, `enable_cdn = false`, `enable_waf = false`,
1 ECS task, single-AZ `db.t4g.micro`.

| Resource | Calculation | Monthly |
|---|---|---|
| NAT Gateway (1x) | $0.045 × 730h + ~5 GB processed | ~$33 |
| ALB | $0.0225 × 730h + ~1 LCU avg | ~$22 |
| ECS Fargate — app task (0.5 vCPU / 1 GB, ~730h) | 0.5 × $0.04048 × 730 + 1 × $0.004445 × 730 | ~$18 |
| ECS Fargate — cron task (0.25 vCPU / 0.5 GB, 1×/min, 1-min minimum billing) | 720h-equivalent × (0.25 × $0.04048 + 0.5 × $0.004445) | ~$9 |
| RDS `db.t4g.micro`, single-AZ, 20 GB | $12 + 20 × $0.115 | ~$14 |
| EFS (light usage, <5 GB, Standard) | 5 × $0.30 | ~$1.50 |
| CloudWatch (5 alarms + dashboard + log storage) | | ~$5 |
| ECR storage | | <$1 |
| **Total** | | **~$104/month** |

## Staging — `vars/staging.tfvars`

Same shape as dev, plus `db.t4g.small`, `enable_cdn = true`, `enable_waf = true`.

| Change vs. dev | Calculation | Delta |
|---|---|---|
| RDS `db.t4g.small` instead of `db.t4g.micro` | ~2× micro's instance cost | +~$12 |
| CloudFront (low traffic, ~10 GB/month out) | 10 × $0.085 + request charges | +~$1.50 |
| WAF — ALB (Web ACL + 3 managed/custom rules) | $5 + 3×$1 | +$8 |
| WAF — CloudFront (separate Web ACL, same 3 rules) | $5 + 3×$1 | +$8 |
| **Total** | | **~$134/month** |

## Prod — `vars/prod.tfvars`

`single_nat_gateway` left at the module default (**false = one NAT per
AZ**, see [architecture.md](architecture.md)), `db_multi_az = true`,
`desired_count = 2`, CDN + WAF on.

| Change vs. staging | Calculation | Delta |
|---|---|---|
| 2 NAT gateways instead of 1 (HA) | +1 × ($0.045 × 730h + processing) | +~$33 |
| 2nd ECS app task | +1 × ~$18 | +~$18 |
| RDS Multi-AZ (standby replica ≈ doubles instance cost) | +~$12 (instance) +~$2.30 (storage) | +~$14 |
| **Total** | | **~$199/month** |

## The single biggest lever

The NAT Gateway(s) are the largest fixed cost relative to how little
this project actually uses them (portfolio-level traffic, not real
users). The real client project this is inspired by solves that with a
self-managed NAT **instance** instead of the managed NAT Gateway
(cheaper at low/moderate traffic, more ops overhead — someone has to
patch and monitor an EC2 instance). Not implemented here by default:
for dev/staging, `single_nat_gateway = true` already removes the
redundant NAT's cost without adding an EC2 instance to operate; for
prod, the HA trade-off is deliberately kept.

## What this still leaves out

Data transfer costs are traffic-dependent and impossible to estimate
honestly without real usage; the CloudFront/data-out figures above
assume low, portfolio-review-level traffic, not production load. None
of these numbers have been checked against an actual AWS bill — this
project has never been left running continuously in a personal AWS
account.
