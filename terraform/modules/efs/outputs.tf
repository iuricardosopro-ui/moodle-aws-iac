output "file_system_id" {
  value = aws_efs_file_system.moodledata.id
}

output "file_system_arn" {
  value = aws_efs_file_system.moodledata.arn
}

output "access_point_id" {
  value = aws_efs_access_point.moodledata.id
}
