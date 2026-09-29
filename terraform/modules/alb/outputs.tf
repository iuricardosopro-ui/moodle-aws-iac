output "dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.moodle.arn
}

output "security_group_id" {
  value = aws_security_group.alb.id
}

output "arn_suffix" {
  description = "Used as a CloudWatch metric dimension (AWS/ApplicationELB LoadBalancer)."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Used as a CloudWatch metric dimension (AWS/ApplicationELB TargetGroup)."
  value       = aws_lb_target_group.moodle.arn_suffix
}
