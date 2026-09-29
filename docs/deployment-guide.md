# Deployment guide

## Prerequisites

- AWS credentials configured locally (or the OIDC role referenced in
  `.github/workflows/terraform.yml` for CI)
- Terraform >= 1.9
- An initial image pushed to ECR so the ECS service has something to pull

## First-time setup, per environment

Each environment is a Terraform **workspace**, sharing the same code
under [`terraform/environments/app`](../terraform/environments/app) and
taking its own values from `vars/<environment>.tfvars`:

```bash
cd terraform/environments/app
terraform init

# one-time, per environment
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

## Deploying an environment

```bash
terraform workspace select dev
terraform plan  -var-file="vars/dev.tfvars"
terraform apply -var-file="vars/dev.tfvars"
```

Swap `dev.tfvars` for `staging.tfvars` or `prod.tfvars` (and select the
matching workspace first) to deploy the other environments. The Moodle
URL is printed as a Terraform output (`moodle_url`); first load takes a
minute while the ECS task pulls the image and the entrypoint waits for
RDS to accept connections.

## Building and pushing the application image

```bash
cd docker
docker build -t <your-ecr-repo>:latest .
docker push <your-ecr-repo>:latest
```

In CI, this is `.github/workflows/docker-build.yml` — it builds, scans
with Trivy, pushes, and forces a new ECS deployment automatically on
every push to `main` that touches `docker/**`.

## Promoting a change through environments

1. Open a PR — `terraform.yml`'s `lint`/`plan` jobs run automatically
   against the `dev` workspace/tfvars.
2. Merge to `main`.
3. Manually trigger `terraform.yml` via `workflow_dispatch`, choosing
   `staging` as the `environment` input, action `apply`.
4. Once verified, repeat with `environment: prod` — this run also
   requires the `production` GitHub Environment's manual approval.

## Enabling CDN / a custom domain for an environment

Set in that environment's `.tfvars`:

```hcl
enable_cdn      = true
domain_name     = "moodle.example.com"   # only if you own the domain
route53_zone_id = "Z0123456789ABCDEFGHIJ"
```

`staging.tfvars` and `prod.tfvars` already ship with `enable_cdn = true`;
`domain_name`/`route53_zone_id` are left empty until a real domain is
registered for this project.

## Rolling back an environment

```bash
terraform workspace select <environment>
terraform apply -var-file="vars/<environment>.tfvars" \
  -var="moodle_image_tag=<previous-known-good-git-sha>"
```

The application image update is independent of the infrastructure
apply — `aws ecs update-service --force-new-deployment` (what the
Docker pipeline calls) can also be run directly to redeploy the
currently-tagged image without touching Terraform at all.
