output "cluster_name" {
  description = "EKS cluster name."
  value       = module.platform.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.platform.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.platform.cluster_endpoint
  sensitive   = true
}

output "configure_kubectl" {
  description = "Command to configure kubectl for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.platform.cluster_name}"
}

output "node_iam_role_arn" {
  description = "EKS Auto Mode node IAM role ARN."
  value       = module.platform.node_iam_role_arn
}

output "kms_key_arn" {
  description = "KMS key ARN used for EKS secret encryption."
  value       = module.platform.kms_key_arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA."
  value       = module.platform.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.platform.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS Auto Mode nodes."
  value       = module.platform.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs for internet-facing load balancers."
  value       = module.platform.public_subnet_ids
}
