variable "name_prefix" {
  description = "Resource name prefix shared across the platform stack."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID hosting the VPC Link ENIs."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs used by the API Gateway VPC Link."
  type        = list(string)
}

variable "internal_alb_listener_arn" {
  description = "Listener ARN for the private/internal ALB that receives API Gateway HTTP API traffic."
  type        = string
}

variable "internal_alb_security_group_id" {
  description = "Security group ID attached to the private/internal ALB listener."
  type        = string
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

variable "http_api_name" {
  description = "Optional API Gateway HTTP API name. Defaults to name_prefix-http-api."
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

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
