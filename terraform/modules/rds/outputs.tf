output "endpoint" {
  value = aws_db_instance.moodle.address
}

output "db_name" {
  value = aws_db_instance.moodle.db_name
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB credentials, for the ECS task to read at runtime."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "security_group_id" {
  value = aws_security_group.rds.id
}

output "instance_id" {
  value = aws_db_instance.moodle.id
}
