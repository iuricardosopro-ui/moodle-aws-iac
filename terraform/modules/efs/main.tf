# Moodle stores user uploads and some caches on disk (moodledata/). With
# more than one ECS task running the app, each task's local disk is
# independent — a file uploaded through task A is invisible to task B
# behind the same load balancer. EFS gives every task the same
# network-mounted filesystem, which is what actually makes the ECS
# service safe to run with desired_count > 1.

resource "aws_efs_file_system" "moodledata" {
  creation_token   = "${var.project_name}-moodledata"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, { Name = "${var.project_name}-moodledata" })
}

resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Allow NFS from the Moodle ECS tasks only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from the Moodle ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-efs-sg" })
}

resource "aws_efs_mount_target" "this" {
  for_each        = toset(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.moodledata.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

# IAM-authenticated access point — scopes every mount to a single
# directory with a fixed POSIX owner (www-data, uid/gid 33 in the
# php:8.2-apache base image) instead of exposing the whole filesystem
# root to every container.
resource "aws_efs_access_point" "moodledata" {
  file_system_id = aws_efs_file_system.moodledata.id

  posix_user {
    uid = 33
    gid = 33
  }

  root_directory {
    path = "/moodledata"

    creation_info {
      owner_uid   = 33
      owner_gid   = 33
      permissions = "0770"
    }
  }

  tags = merge(var.tags, { Name = "${var.project_name}-moodledata-ap" })
}
