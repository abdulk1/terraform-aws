output "alb_arn" {
  description = "Internal ALB ARN."
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix, useful for CloudWatch metric dimensions."
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "Internal DNS name for the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the ALB, used for alias records."
  value       = aws_lb.this.zone_id
}

output "listener_arn" {
  description = "Default listener ARN. Pass this to the API Gateway module."
  value       = aws_lb_listener.this.arn
}

output "listener_port" {
  description = "Default listener port."
  value       = aws_lb_listener.this.port
}

output "security_group_id" {
  description = "Security group attached to the ALB."
  value       = aws_security_group.alb.id
}
