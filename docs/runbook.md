# Runbook

Operational responses to the failure modes most likely to show up on
this project. Written for future-me at 2am as much as for anyone else.

## The ECS service won't reach a healthy target

**Symptom:** ALB returns 502/504, or the `alb-unhealthy-hosts` alarm
fires.

1. Check the task's own status first:
   `aws ecs describe-services --cluster <cluster> --services <service>`
   — look at `events` for the actual failure reason (most common:
   `CannotPullContainerError`, or the task starting and immediately
   stopping).
2. Check `/ecs/<project>-moodle` in CloudWatch Logs for the container's
   stdout. `entrypoint.sh` logs its DB-connection retry loop — if it
   never says "Database is reachable", the problem is RDS/security
   groups, not the Moodle app itself.
3. Confirm the ECS service's security group actually has the ALB's
   security group as its ingress source (see `ecs_service` in
   `environments/app/main.tf`) — a manual edit outside Terraform is the
   usual way this drifts.

## Moodle cron hasn't run recently

**Symptom:** scheduled notifications, forum digests, or backups aren't
happening.

1. `aws events list-rule-names-by-target --target-arn <cluster-arn>` to
   confirm the EventBridge rule is enabled.
2. Check `/ecs/<project>-moodle` log stream prefixed `moodle-cron` — a
   task that starts and exits non-zero every minute usually means a DB
   credential or IAM (`iam:PassRole`) issue introduced by an unrelated
   change to the execution/task role.
3. As a stopgap, run cron.php manually against the same task
   definition: `aws ecs run-task --cluster <cluster> --task-definition
   <project>-moodle-cron --launch-type FARGATE --network-configuration
   ...`

## Uploads disappear or 404 intermittently

**Symptom:** a file uploaded through one request 404s on a later one.

This is the exact failure EFS was added to prevent (see
[architecture.md](architecture.md)). If it's happening again:

1. Confirm the running task definition actually has the `moodledata`
   volume + mount point — a task definition revision that dropped it
   (e.g. someone edited the console instead of Terraform) will silently
   fall back to local disk.
2. Check the EFS mount targets are healthy in every AZ the ECS tasks can
   land in — a missing mount target in one AZ makes tasks scheduled
   there fail to start instead of degrading gracefully.

## RDS free storage alarm fires

1. `aws rds describe-db-instances` — check `AllocatedStorage` vs actual
   usage.
2. Storage autoscaling isn't enabled by default here; increasing
   `allocated_storage` in the relevant `.tfvars` and re-applying is a
   normal, low-risk change (RDS resizes online).
3. If this happens repeatedly in `staging`/`prod`, that's a sign to
   revisit retention (backups, binlogs) before just raising the number.

## CloudFront is serving a stale page after a deploy

Expected for cacheable paths, if any get added later — the current
default cache behavior sets `default_ttl = 0` specifically to avoid
this for the whole app. If it happens anyway:

```bash
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

## A `terraform apply` partially fails

1. Re-run `terraform plan` first — most of these modules are idempotent
   and a second `apply` finishes cleanly.
2. If a resource is left in an inconsistent state (rare, but EFS mount
   targets across AZs are the most likely candidate), `terraform state
   list` + targeted `terraform apply -target=<resource>` is safer than a
   full re-apply while debugging.
