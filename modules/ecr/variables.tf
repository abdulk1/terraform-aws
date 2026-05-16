variable "name_prefix" {
  description = "Shared name prefix. Two ECR repositories are created at <name_prefix>/base and <name_prefix>/app/nonprod, and the generated IAM policy also permits create/push/pull on any nested repository under those prefixes."
  type        = string
}

variable "aws_region" {
  description = "AWS region the ECR repositories live in. Used to scope IAM resource ARNs."
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability for the root repositories and for repositories AWS auto-creates via the creation templates."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Whether ECR scans images automatically on push."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "ECR encryption type. KMS requires kms_key_arn."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for repository encryption. Required when encryption_type is KMS."
  type        = string
  default     = null
}

variable "lifecycle_policy_enabled" {
  description = "Whether to attach a lifecycle policy to the root repositories and propagate one to repositories AWS auto-creates via the creation templates."
  type        = bool
  default     = true
}

variable "lifecycle_policy_json" {
  description = "Custom lifecycle policy JSON. When null and lifecycle_policy_enabled is true, a default policy is applied that expires untagged images after 14 days and keeps the most recent 100 images per repository."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
