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
