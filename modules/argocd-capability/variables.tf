variable "name_prefix" {
  description = "Resource name prefix shared across the platform stack."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name to attach the Argo CD capability to."
  type        = string
}

variable "capability_name" {
  description = "Name of the Argo CD capability resource on the cluster."
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD CRDs. Leave null to use the AWS default."
  type        = string
  default     = null
}

variable "delete_propagation_policy" {
  description = "What happens to Argo CD CRDs when the capability is deleted. RETAIN keeps Application/AppProject resources; DELETE removes them."
  type        = string
  default     = "RETAIN"

  validation {
    condition     = contains(["RETAIN", "DELETE"], var.delete_propagation_policy)
    error_message = "delete_propagation_policy must be RETAIN or DELETE."
  }
}

variable "idc_instance_arn" {
  description = "AWS IAM Identity Center instance ARN used for Argo CD authentication. Local users are not supported."
  type        = string
}

variable "idc_region" {
  description = "AWS region for the IAM Identity Center instance. Leave null to use the same region as the cluster."
  type        = string
  default     = null
}

variable "rbac_role_mappings" {
  description = "Mappings from Argo CD RBAC roles (e.g. ADMIN) to IAM Identity Center users or groups."
  type = list(object({
    role = string
    identities = list(object({
      id   = string
      type = string
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for mapping in var.rbac_role_mappings :
      alltrue([for identity in mapping.identities : contains(["SSO_USER", "SSO_GROUP"], identity.type)])
    ])
    error_message = "rbac_role_mappings identity type must be SSO_USER or SSO_GROUP."
  }
}

variable "vpc_endpoint_ids" {
  description = "VPC endpoint IDs that should reach the Argo CD UI privately. Leave empty for the default network path."
  type        = list(string)
  default     = []
}

variable "enable_secrets_manager_access" {
  description = "Whether to grant the capability role read access to Secrets Manager secrets matching secrets_manager_secret_arns. Needed if Argo CD reads Git credentials from Secrets Manager."
  type        = bool
  default     = false
}

variable "secrets_manager_secret_arns" {
  description = "Secrets Manager ARNs (wildcards allowed) the capability role can read."
  type        = list(string)
  default     = []
}

variable "enable_codeconnections_access" {
  description = "Whether to grant the capability role use of CodeConnections connections. Needed when Argo CD authenticates to Git via AWS CodeConnections."
  type        = bool
  default     = false
}

variable "codeconnections_connection_arns" {
  description = "CodeConnections connection ARNs (wildcards allowed) the capability role can use."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
