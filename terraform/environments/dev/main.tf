module "tags" {
  source = "../../modules/tags"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner
  cost_center  = var.cost_center
}

module "network" {
  source = "../../modules/network"

  project_name         = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = module.tags.tags
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = "${var.project_name}-${var.environment}"
  tags         = module.tags.tags
}

module "alb" {
  source = "../../modules/alb"

  project_name      = "${var.project_name}-${var.environment}"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  tags              = module.tags.tags
}

# Created here (not inside the ECS module) because both the ECS service and
# the RDS module's ingress rule need to reference it — declaring it inside
# either module would create a module dependency cycle (ECS needs RDS's
# endpoint/secret, RDS needs ECS's security group).
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Allow inbound traffic from the ALB only"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.tags.tags, { Name = "${var.project_name}-${var.environment}-ecs-sg" })
}

module "efs" {
  source = "../../modules/efs"

  project_name           = "${var.project_name}-${var.environment}"
  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
  ecs_security_group_id  = aws_security_group.ecs_service.id
  tags                   = module.tags.tags
}

module "rds" {
  source = "../../modules/rds"

  project_name               = "${var.project_name}-${var.environment}"
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_ids = [aws_security_group.ecs_service.id]
  tags                       = module.tags.tags
}

module "ecs" {
  source = "../../modules/ecs"

  project_name              = "${var.project_name}-${var.environment}"
  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_subnet_ids
  alb_security_group_id     = module.alb.security_group_id
  service_security_group_id = aws_security_group.ecs_service.id
  target_group_arn          = module.alb.target_group_arn
  ecr_repository_url        = module.ecr.repository_url
  image_tag                 = var.moodle_image_tag
  db_endpoint               = module.rds.endpoint
  db_name                   = module.rds.db_name
  db_secret_arn             = module.rds.secret_arn
  efs_file_system_id        = module.efs.file_system_id
  efs_file_system_arn       = module.efs.file_system_arn
  efs_access_point_id       = module.efs.access_point_id
  tags                      = module.tags.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name            = "${var.project_name}-${var.environment}"
  aws_region               = var.aws_region
  ecs_cluster_name         = module.ecs.cluster_name
  ecs_service_name         = module.ecs.service_name
  alb_arn_suffix           = module.alb.arn_suffix
  target_group_arn_suffix  = module.alb.target_group_arn_suffix
  rds_instance_id          = module.rds.instance_id
  alarm_email              = var.alarm_email
  tags                     = module.tags.tags
}

module "cdn" {
  count  = var.enable_cdn ? 1 : 0
  source = "../../modules/cdn"

  project_name = "${var.project_name}-${var.environment}"
  alb_dns_name = module.alb.dns_name
  tags         = module.tags.tags
}

module "dns" {
  source = "../../modules/dns"

  domain_name               = var.domain_name
  route53_zone_id           = var.route53_zone_id
  cloudfront_domain_name    = coalesce(one(module.cdn[*].domain_name), "")
  cloudfront_hosted_zone_id = coalesce(one(module.cdn[*].hosted_zone_id), "")
}
