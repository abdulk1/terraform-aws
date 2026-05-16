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

output "configure_kubectl" {
  description = "Command to configure kubectl for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
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

output "cluster_addons" {
  description = "EKS add-ons managed by Terraform."
  value       = module.eks.cluster_addons
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS Auto Mode nodes."
  value       = module.network.private_subnet_ids
}

output "vpc_endpoint_security_group_id" {
  description = "Security group attached to AWS service interface endpoints."
  value       = module.network.vpc_endpoint_security_group_id
}

output "internal_alb_arn" {
  description = "Internal ALB ARN when provisioned by this stack."
  value       = try(module.internal_alb[0].alb_arn, null)
}

output "internal_alb_dns_name" {
  description = "Internal ALB DNS name."
  value       = try(module.internal_alb[0].alb_dns_name, null)
}

output "internal_alb_zone_id" {
  description = "Internal ALB Route 53 zone ID for alias records."
  value       = try(module.internal_alb[0].alb_zone_id, null)
}

output "internal_alb_listener_arn" {
  description = "Internal ALB default listener ARN."
  value       = try(module.internal_alb[0].listener_arn, null)
}

output "internal_alb_security_group_id" {
  description = "Internal ALB security group ID. Attach EKS workload security groups and TargetGroupBinding controllers to this."
  value       = try(module.internal_alb[0].security_group_id, null)
}

output "http_api_endpoint" {
  description = "API Gateway HTTP API endpoint."
  value       = try(module.api_gateway[0].http_api_endpoint, null)
}

output "http_api_vpc_link_id" {
  description = "API Gateway VPC Link ID."
  value       = try(module.api_gateway[0].http_api_vpc_link_id, null)
}

output "api_gateway_vpc_link_security_group_id" {
  description = "Security group ID used by the API Gateway VPC Link ENIs."
  value       = try(module.api_gateway[0].vpc_link_security_group_id, null)
}

output "argocd_server_url" {
  description = "Argo CD UI/API URL when the capability is enabled."
  value       = try(module.argocd_capability[0].argocd_server_url, null)
}

output "argocd_capability_arn" {
  description = "ARN of the Argo CD EKS capability."
  value       = try(module.argocd_capability[0].capability_arn, null)
}

output "argocd_capability_role_arn" {
  description = "IAM role assumed by the Argo CD capability service."
  value       = try(module.argocd_capability[0].capability_role_arn, null)
}

output "argocd_idc_managed_application_arn" {
  description = "IAM Identity Center managed application ARN created for Argo CD."
  value       = try(module.argocd_capability[0].idc_managed_application_arn, null)
}
