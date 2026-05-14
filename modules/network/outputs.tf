output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS Auto Mode nodes."
  value       = module.vpc.private_subnets
}

output "private_route_table_ids" {
  description = "Private route table IDs."
  value       = module.vpc.private_route_table_ids
}

output "vpc_endpoint_security_group_id" {
  description = "Security group attached to AWS service interface endpoints."
  value       = aws_security_group.vpc_endpoints.id
}

output "vpc_flow_log_id" {
  description = "VPC flow log ID."
  value       = try(aws_flow_log.this[0].id, null)
}
