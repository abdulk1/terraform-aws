variable "project_name" {
  description = "Short project name used in resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region for the environment."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the environment VPC."
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 3
}

variable "private_subnet_cidrs" {
  description = "Optional explicit private subnet CIDRs."
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version."
  type        = string
  default     = "1.35"
}

variable "auto_mode_node_pools" {
  description = "Built-in EKS Auto Mode node pools to enable."
  type        = list(string)
  default     = ["system", "general-purpose"]
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Grant the Terraform caller cluster admin through an EKS access entry."
  type        = bool
  default     = true
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs to grant AmazonEKSClusterAdminPolicy on the cluster."
  type        = list(string)
  default     = []
}

variable "cluster_viewer_principal_arns" {
  description = "IAM principal ARNs to grant AmazonEKSViewPolicy on the cluster."
  type        = list(string)
  default     = []
}

variable "enabled_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch retention in days for EKS control plane logs."
  type        = number
  default     = 90
}

variable "enable_vpc_flow_logs" {
  description = "Whether to send VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "vpc_flow_log_retention_days" {
  description = "CloudWatch retention in days for VPC flow logs."
  type        = number
  default     = 90
}

variable "vpc_flow_log_kms_key_id" {
  description = "Optional KMS key ARN for the VPC flow log group."
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "Waiting period before deleting the EKS secrets encryption KMS key."
  type        = number
  default     = 30
}

variable "control_plane_scaling_tier" {
  description = "Optional EKS provisioned control plane scaling tier, for example tier-xl."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Whether to enable EKS deletion protection."
  type        = bool
  default     = false
}

variable "upgrade_support_type" {
  description = "EKS version support policy: STANDARD or EXTENDED."
  type        = string
  default     = "STANDARD"
}

variable "enable_zonal_shift" {
  description = "Whether to enable ARC zonal shift for the cluster."
  type        = bool
  default     = true
}

variable "enable_http_api_gateway" {
  description = "Whether to create an API Gateway HTTP API with a VPC Link private integration to an internal ALB listener."
  type        = bool
  default     = false
}

variable "http_api_name" {
  description = "Optional API Gateway HTTP API name."
  type        = string
  default     = null
}

variable "http_api_stage_name" {
  description = "API Gateway HTTP API stage name."
  type        = string
  default     = "$default"
}

variable "http_api_route_keys" {
  description = "HTTP API route keys forwarded to the internal ALB."
  type        = list(string)
  default     = ["ANY /", "ANY /{proxy+}"]
}

variable "http_api_integration_method" {
  description = "HTTP method used by the HTTP proxy integration to the private ALB."
  type        = string
  default     = "ANY"
}

variable "http_api_request_parameter_mapping" {
  description = "HTTP API request parameter mapping for the private integration."
  type        = map(string)
  default = {
    "overwrite:path" = "$request.path"
  }
}

variable "http_api_timeout_milliseconds" {
  description = "HTTP API private integration timeout in milliseconds."
  type        = number
  default     = 30000
}

variable "http_api_disable_execute_api_endpoint" {
  description = "Whether to disable the default execute-api endpoint."
  type        = bool
  default     = false
}

variable "http_api_authorization_type" {
  description = "HTTP API route authorization type when no JWT authorizer is configured."
  type        = string
  default     = "AWS_IAM"
}

variable "http_api_authorizer_id" {
  description = "Existing authorizer ID to use when http_api_authorization_type is CUSTOM or externally managed JWT."
  type        = string
  default     = null
}

variable "http_api_jwt_authorizer" {
  description = "Optional JWT authorizer configuration. When set, routes use JWT authorization."
  type = object({
    name             = string
    audience         = list(string)
    issuer           = string
    identity_sources = optional(list(string), ["$request.header.Authorization"])
  })
  default = null
}

variable "http_api_private_integration_tls_server_name" {
  description = "Optional backend server name for TLS verification between API Gateway and the private ALB listener."
  type        = string
  default     = null
}

variable "http_api_access_log_retention_days" {
  description = "CloudWatch retention in days for HTTP API access logs."
  type        = number
  default     = 365
}

variable "http_api_access_log_kms_key_id" {
  description = "Optional KMS key ARN for the HTTP API access log group."
  type        = string
  default     = null
}

variable "internal_alb_listener_arn" {
  description = "Listener ARN for the private/internal ALB that receives API Gateway HTTP API traffic."
  type        = string
  default     = null
}

variable "internal_alb_security_group_id" {
  description = "Security group ID attached to the private/internal ALB listener."
  type        = string
  default     = null
}

variable "internal_alb_listener_port" {
  description = "Private/internal ALB listener port used by API Gateway VPC Link."
  type        = number
  default     = 443
}

variable "manage_internal_alb_security_group_rule" {
  description = "Whether Terraform should add an ingress rule on the internal ALB security group from the API Gateway VPC Link security group."
  type        = bool
  default     = true
}

variable "enable_argocd_capability" {
  description = "Whether to create the EKS-managed Argo CD capability on the cluster. Requires AWS IAM Identity Center."
  type        = bool
  default     = false
}

variable "argocd_capability_name" {
  description = "Name of the Argo CD capability resource."
  type        = string
  default     = "argocd"
}

variable "argocd_idc_instance_arn" {
  description = "IAM Identity Center instance ARN used by Argo CD for authentication."
  type        = string
  default     = null
}

variable "argocd_idc_region" {
  description = "AWS region of the IAM Identity Center instance. Defaults to the cluster region."
  type        = string
  default     = null
}

variable "argocd_rbac_role_mappings" {
  description = "Argo CD RBAC role mappings, for example admin assignment to Identity Center users/groups."
  type = list(object({
    role = string
    identities = list(object({
      id   = string
      type = string
    }))
  }))
  default = []
}

variable "argocd_vpc_endpoint_ids" {
  description = "Optional VPC endpoint IDs for private access to the Argo CD UI."
  type        = list(string)
  default     = []
}

variable "argocd_delete_propagation_policy" {
  description = "Behavior for Argo CD CRDs on capability delete."
  type        = string
  default     = "RETAIN"
}

variable "argocd_enable_secrets_manager_access" {
  description = "Grant the Argo CD capability role read access to specific Secrets Manager secrets."
  type        = bool
  default     = false
}

variable "argocd_secrets_manager_secret_arns" {
  description = "Secrets Manager ARNs Argo CD may read."
  type        = list(string)
  default     = []
}

variable "argocd_enable_codeconnections_access" {
  description = "Grant the Argo CD capability role use of CodeConnections."
  type        = bool
  default     = false
}

variable "argocd_codeconnections_connection_arns" {
  description = "CodeConnections connection ARNs Argo CD may use."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}
