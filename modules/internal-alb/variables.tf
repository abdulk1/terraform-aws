variable "name_prefix" {
  description = "Resource name prefix shared across the platform stack."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the internal ALB is provisioned."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs the ALB attaches to. Must cover at least two AZs."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least two subnets across distinct AZs."
  }
}

variable "alb_name" {
  description = "Optional ALB name. Defaults to name_prefix-internal."
  type        = string
  default     = null
}

variable "listener_protocol" {
  description = "Listener protocol. HTTPS requires certificate_arn."
  type        = string
  default     = "HTTPS"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.listener_protocol)
    error_message = "listener_protocol must be HTTP or HTTPS."
  }
}

variable "listener_port" {
  description = "Listener port for the default ALB listener."
  type        = number
  default     = 443
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Required when listener_protocol is HTTPS."
  type        = string
  default     = null
}

variable "additional_certificate_arns" {
  description = "Additional ACM certificate ARNs attached to the HTTPS listener for SNI."
  type        = list(string)
  default     = []
}

variable "ssl_policy" {
  description = "SSL negotiation policy for the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "idle_timeout" {
  description = "ALB idle timeout in seconds."
  type        = number
  default     = 60
}

variable "deletion_protection" {
  description = "Whether to enable ALB deletion protection."
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "Whether the ALB drops HTTP headers with invalid characters. FISMA baseline: true."
  type        = bool
  default     = true
}

variable "ingress_cidr_blocks" {
  description = "Optional CIDR blocks allowed to reach the listener directly. Leave empty when the only ingress is from in-VPC consumers (API Gateway VPC Link, EKS pods) that attach their own security groups."
  type        = list(string)
  default     = []
}

variable "ingress_security_group_ids" {
  description = "Security group IDs granted ingress to the listener port. Use this for in-VPC consumers like API Gateway VPC Link ENIs."
  type        = list(string)
  default     = []
}

variable "access_logs" {
  description = "Optional S3 access log configuration for the ALB."
  type = object({
    bucket  = string
    prefix  = optional(string, null)
    enabled = optional(bool, true)
  })
  default = null
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
