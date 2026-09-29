locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  project_name         = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = "${var.project_name}-${var.environment}"
  tags         = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  project_name      = "${var.project_name}-${var.environment}"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  tags              = local.common_tags
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

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-ecs-sg" })
}

module "rds" {
  source = "../../modules/rds"

  project_name               = "${var.project_name}-${var.environment}"
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_ids = [aws_security_group.ecs_service.id]
  tags                       = local.common_tags
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
  tags                      = local.common_tags
}
