output "repository_names" {
  description = "Map of logical key (base, app_nonprod) to ECR repository name."
  value       = { for k, r in aws_ecr_repository.this : k => r.name }
}

output "repository_arns" {
  description = "Map of logical key to ECR repository ARN."
  value       = { for k, r in aws_ecr_repository.this : k => r.arn }
}

output "repository_urls" {
  description = "Map of logical key to ECR repository URL. Use the URL with docker tag/push."
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "root_repository_arns" {
  description = "List of ARNs for the two root repositories. Useful for granting consumers (e.g. argocd-capability) pull access."
  value       = [for r in aws_ecr_repository.this : r.arn]
}

output "scoped_repository_arns" {
  description = "All resource ARNs covered by the generated IAM policy, including wildcards for nested repositories."
  value       = local.scoped_repository_arns
}

output "push_pull_policy_arn" {
  description = "ARN of the managed IAM policy granting create/push/pull on both prefixes. Attach this to any IAM role or user that needs access."
  value       = aws_iam_policy.push_pull.arn
}

output "push_pull_policy_json" {
  description = "Raw JSON of the push/pull policy, for callers that prefer inline statements over the managed policy."
  value       = data.aws_iam_policy_document.push_pull.json
}
