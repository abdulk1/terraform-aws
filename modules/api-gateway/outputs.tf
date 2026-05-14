output "http_api_id" {
  description = "API Gateway HTTP API ID."
  value       = aws_apigatewayv2_api.http.id
}

output "http_api_endpoint" {
  description = "API Gateway HTTP API endpoint."
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "http_api_vpc_link_id" {
  description = "API Gateway VPC Link ID."
  value       = aws_apigatewayv2_vpc_link.http.id
}

output "vpc_link_security_group_id" {
  description = "Security group ID used by the API Gateway VPC Link ENIs."
  value       = aws_security_group.vpc_link.id
}
