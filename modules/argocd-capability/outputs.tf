output "capability_arn" {
  description = "ARN of the Argo CD capability resource."
  value       = aws_eks_capability.argocd.arn
}

output "capability_name" {
  description = "Name of the Argo CD capability resource."
  value       = aws_eks_capability.argocd.capability_name
}

output "argocd_server_url" {
  description = "Argo CD UI/API URL provisioned by EKS."
  value       = try(aws_eks_capability.argocd.configuration[0].argo_cd[0].server_url, null)
}

output "argocd_namespace" {
  description = "Namespace where Argo CD CRDs are installed."
  value       = try(aws_eks_capability.argocd.configuration[0].argo_cd[0].namespace, null)
}

output "idc_managed_application_arn" {
  description = "IAM Identity Center managed application ARN created for Argo CD."
  value       = try(aws_eks_capability.argocd.configuration[0].argo_cd[0].aws_idc[0].idc_managed_application_arn, null)
}

output "capability_role_arn" {
  description = "IAM capability role ARN assumed by the EKS capability service."
  value       = aws_iam_role.capability.arn
}
