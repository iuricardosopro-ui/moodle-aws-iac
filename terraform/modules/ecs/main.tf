resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "moodle" {
  name              = "/ecs/${var.project_name}-moodle"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.project_name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Execution role also needs to read the DB secret to inject it into the container at startup.
data "aws_iam_policy_document" "read_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_role_policy" "execution_read_secret" {
  name   = "${var.project_name}-read-db-secret"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_secret.json
}

resource "aws_iam_role" "task" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = var.tags
}

resource "aws_ecs_task_definition" "moodle" {
  family                   = "${var.project_name}-moodle"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  volume {
    name = "moodledata"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "moodle"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        { containerPort = 8080, protocol = "tcp" }
      ]
      mountPoints = [
        { sourceVolume = "moodledata", containerPath = "/var/www/moodledata", readOnly = false }
      ]
      environment = [
        { name = "MOODLE_DATABASE_HOST", value = var.db_endpoint },
        { name = "MOODLE_DATABASE_NAME", value = var.db_name },
      ]
      secrets = [
        { name = "MOODLE_DATABASE_USER", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "MOODLE_DATABASE_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.moodle.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "moodle"
        }
      }
    }
  ])

  tags = var.tags
}

# Simplified to the whole filesystem rather than scoped to the access
# point ARN, to avoid a data-source dependency on account ID here — the
# access point's own POSIX root/permissions already constrain what a
# mount can see and write.
data "aws_iam_policy_document" "efs_access" {
  statement {
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite"]
    resources = [var.efs_file_system_arn]
  }
}

resource "aws_iam_role_policy" "task_efs_access" {
  name   = "${var.project_name}-efs-access"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.efs_access.json
}

data "aws_region" "current" {}

resource "aws_ecs_service" "moodle" {
  name            = "${var.project_name}-moodle-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.moodle.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.service_security_group_id]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "moodle"
    container_port   = 8080
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = var.tags
}
