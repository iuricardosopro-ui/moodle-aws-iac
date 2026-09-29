# Moodle requires admin/cli/cron.php to run at least every minute to
# process notifications, forum digests, scheduled backups and other
# background tasks — without it the app "looks fine" but several
# features silently stop working. Running it as a `while true; sleep 60`
# loop inside the main container mixes two responsibilities in one
# process; instead it runs as its own scheduled Fargate task, invoked by
# EventBridge on a fixed rate.

data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "cron" {
  family                   = "${var.project_name}-moodle-cron"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cron_cpu
  memory                   = var.cron_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "moodle-cron"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      # Overrides the image's default CMD (which starts Apache) to run
      # cron.php once and exit — EventBridge starts a fresh task on
      # every trigger, so there is no long-running process to manage.
      command = ["php", "/var/www/html/admin/cli/cron.php"]
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
          "awslogs-stream-prefix" = "moodle-cron"
        }
      }
    }
  ])

  tags = var.tags
}

data "aws_iam_policy_document" "events_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "events_run_task" {
  name               = "${var.project_name}-cron-events-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "events_run_task" {
  statement {
    actions   = ["ecs:RunTask"]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.cron.family}:*"]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.execution.arn, aws_iam_role.task.arn]
  }
}

resource "aws_iam_role_policy" "events_run_task" {
  name   = "${var.project_name}-cron-events-run-task"
  role   = aws_iam_role.events_run_task.id
  policy = data.aws_iam_policy_document.events_run_task.json
}

resource "aws_cloudwatch_event_rule" "moodle_cron" {
  name                = "${var.project_name}-moodle-cron"
  description         = "Triggers the Moodle cron.php task on a fixed schedule, as required by Moodle's own documentation."
  schedule_expression = var.cron_schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "moodle_cron" {
  rule     = aws_cloudwatch_event_rule.moodle_cron.name
  arn      = aws_ecs_cluster.this.arn
  role_arn = aws_iam_role.events_run_task.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.cron.arn
    task_count          = 1
    launch_type         = "FARGATE"
    platform_version    = "LATEST"

    network_configuration {
      subnets          = var.private_subnet_ids
      security_groups  = [var.service_security_group_id]
      assign_public_ip = false
    }
  }
}
