variable "project_name" {
  description = "Short project name used in resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-30 lowercase alphanumeric or hyphen characters, starting and ending with alphanumeric."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of dev, test, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for the environment."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the environment VPC. A /16 is recommended for EKS growth."
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "private_subnet_cidrs" {
  description = "Optional explicit private subnet CIDRs. Leave empty to derive /20 subnets from vpc_cidr."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "Optional explicit public subnet CIDRs. Leave empty to derive /24 subnets from vpc_cidr."
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway. Set false for one NAT gateway per AZ."
  type        = bool
  default     = true
}

variable "enable_public_load_balancer_subnet_tags" {
  description = "Whether to tag public subnets for internet-facing Kubernetes load balancer discovery. Keep false for private ALB ingress through API Gateway."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version."
  type        = string
  default     = "1.33"
}

variable "auto_mode_node_pools" {
  description = "Built-in EKS Auto Mode node pools to enable."
  type        = list(string)
  default     = ["system", "general-purpose"]

  validation {
    condition     = alltrue([for node_pool in var.auto_mode_node_pools : contains(["system", "general-purpose"], node_pool)])
    error_message = "auto_mode_node_pools may only contain system and general-purpose."
  }
}

variable "endpoint_public_access" {
  description = "Whether to enable the public EKS API endpoint. Keep false unless you restrict endpoint_public_access_cidrs."
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint when endpoint_public_access is true."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Grant the Terraform caller cluster admin through an EKS access entry. Useful for bootstrap; prefer explicit admin principals for steady state."
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

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "kms_key_deletion_window_in_days must be between 7 and 30."
  }
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
  description = "EKS version support policy. STANDARD avoids extended support charges; EXTENDED keeps old versions longer at extra cost."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.upgrade_support_type)
    error_message = "upgrade_support_type must be STANDARD or EXTENDED."
  }
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
  description = "Optional API Gateway HTTP API name. Defaults to project-environment-http-api."
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
  description = "HTTP API request parameter mapping for the private integration. The default removes non-default stage prefixes before forwarding to the ALB."
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
  description = "Whether to disable the default execute-api endpoint. Set true only after attaching a custom domain."
  type        = bool
  default     = false
}

variable "http_api_authorization_type" {
  description = "HTTP API route authorization type when no JWT authorizer is configured."
  type        = string
  default     = "AWS_IAM"

  validation {
    condition     = contains(["AWS_IAM", "CUSTOM", "JWT", "NONE"], var.http_api_authorization_type)
    error_message = "http_api_authorization_type must be AWS_IAM, CUSTOM, JWT, or NONE."
  }
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

variable "private_subnet_tags" {
  description = "Additional tags to apply to private subnets."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags to apply to public subnets."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}
