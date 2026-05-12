output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID."
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Shared node security group ID."
  value       = module.eks.node_security_group_id
}

output "node_iam_role_arn" {
  description = "EKS Auto Mode node IAM role ARN."
  value       = module.eks.node_iam_role_arn
}

output "kms_key_arn" {
  description = "KMS key ARN used for EKS secret encryption."
  value       = module.eks.kms_key_arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA."
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS Auto Mode nodes."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs for NAT gateways and approved edge resources."
  value       = module.vpc.public_subnets
}

output "vpc_flow_log_id" {
  description = "VPC flow log ID."
  value       = try(aws_flow_log.this[0].id, null)
}

output "http_api_id" {
  description = "API Gateway HTTP API ID."
  value       = try(aws_apigatewayv2_api.http[0].id, null)
}

output "http_api_endpoint" {
  description = "API Gateway HTTP API endpoint."
  value       = try(aws_apigatewayv2_api.http[0].api_endpoint, null)
}

output "http_api_vpc_link_id" {
  description = "API Gateway VPC Link ID."
  value       = try(aws_apigatewayv2_vpc_link.http[0].id, null)
}

output "api_gateway_vpc_link_security_group_id" {
  description = "Security group ID used by the API Gateway VPC Link ENIs."
  value       = try(aws_security_group.api_gateway_vpc_link[0].id, null)
}
