variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "aws_region" {
  description = "AWS region for the cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster runs."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the cluster and Auto Mode nodes."
  type        = list(string)
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

  validation {
    condition     = alltrue([for node_pool in var.auto_mode_node_pools : contains(["system", "general-purpose"], node_pool)])
    error_message = "auto_mode_node_pools may only contain system and general-purpose."
  }
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

variable "enable_guardduty_agent_addon" {
  description = "Whether to install the Amazon GuardDuty EKS Runtime Monitoring agent as an EKS add-on. GuardDuty Runtime Monitoring must also be enabled in the account."
  type        = bool
  default     = true
}

variable "guardduty_agent_addon_version" {
  description = "Optional pinned version for the aws-guardduty-agent EKS add-on. Defaults to the most recent compatible version."
  type        = string
  default     = null
}

variable "guardduty_agent_addon_configuration_values" {
  description = "Optional JSON configuration string for the aws-guardduty-agent EKS add-on."
  type        = string
  default     = null
}

variable "enable_secrets_store_csi_driver_provider_addon" {
  description = "Whether to install the AWS Secrets Store CSI Driver provider EKS add-on for mounting Secrets Manager and SSM Parameter Store values into pods."
  type        = bool
  default     = true
}

variable "secrets_store_csi_driver_provider_addon_version" {
  description = "Optional pinned version for the aws-secrets-store-csi-driver-provider EKS add-on. Defaults to the most recent compatible version."
  type        = string
  default     = null
}

variable "secrets_store_csi_driver_provider_addon_configuration_values" {
  description = "Optional JSON configuration string for the aws-secrets-store-csi-driver-provider EKS add-on."
  type        = string
  default     = null
}

variable "additional_eks_addons" {
  description = "Additional EKS add-ons to install. EKS Auto Mode already includes the Pod Identity Agent, so do not add eks-pod-identity-agent here unless non-Auto-Mode compute is introduced."
  type = map(object({
    name                 = optional(string)
    before_compute       = optional(bool, false)
    most_recent          = optional(bool, true)
    addon_version        = optional(string)
    configuration_values = optional(string)
    pod_identity_association = optional(list(object({
      role_arn        = string
      service_account = string
    })))
    preserve                    = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "cluster_log_retention_days" {
  description = "CloudWatch retention in days for EKS control plane logs."
  type        = number
  default     = 90
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

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
