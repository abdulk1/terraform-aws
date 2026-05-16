variable "name_prefix" {
  description = "Resource name prefix shared across the platform stack."
  type        = string
}

variable "bucket_name" {
  description = "Optional explicit S3 bucket name. Defaults to name_prefix-ui."
  type        = string
  default     = null
}

variable "origin_access_control_name" {
  description = "Optional explicit CloudFront Origin Access Control name. Defaults to name_prefix-ui-oac."
  type        = string
  default     = null
}

variable "cache_policy_name" {
  description = "Optional explicit CloudFront cache policy name. Defaults to name_prefix-ui-cache."
  type        = string
  default     = null
}

variable "comment" {
  description = "Optional CloudFront distribution comment."
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Default root object served at the distribution root. For a React SPA this is index.html."
  type        = string
  default     = "index.html"
}

variable "aliases" {
  description = "Custom domain aliases (CNAMEs) for the distribution. Each alias must be covered by acm_certificate_arn."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom aliases. Must be issued in us-east-1."
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version when a custom certificate is in use."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_All, PriceClass_200, or PriceClass_100."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "http_version" {
  description = "Maximum HTTP version supported by the distribution."
  type        = string
  default     = "http2and3"

  validation {
    condition     = contains(["http1.1", "http2", "http2and3", "http3"], var.http_version)
    error_message = "http_version must be one of http1.1, http2, http2and3, http3."
  }
}

variable "ipv6_enabled" {
  description = "Whether the distribution serves IPv6."
  type        = bool
  default     = true
}

variable "web_acl_id" {
  description = "Optional AWS WAFv2 web ACL ARN attached to the distribution. Must be a CloudFront-scoped (us-east-1) ACL."
  type        = string
  default     = null
}

variable "spa_error_responses" {
  description = "When true, 403 and 404 origin responses are rewritten to the default root object with HTTP 200 so client-side SPA routes resolve."
  type        = bool
  default     = true
}

variable "spa_error_caching_min_ttl" {
  description = "Minimum TTL CloudFront caches the SPA rewrite responses for."
  type        = number
  default     = 10
}

variable "versioning_enabled" {
  description = "Whether S3 bucket versioning is enabled. Keep on so rollbacks of UI bundles are possible."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Optional customer-managed KMS key ARN for S3 bucket encryption. When null, SSE-S3 (AES256) is used."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow terraform destroy to delete a non-empty bucket. Leave false outside of ephemeral environments."
  type        = bool
  default     = false
}

variable "geo_restriction" {
  description = "CloudFront geo restriction. Use restriction_type none to disable."
  type = object({
    restriction_type = string
    locations        = optional(list(string), [])
  })
  default = {
    restriction_type = "none"
    locations        = []
  }

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction.restriction_type)
    error_message = "geo_restriction.restriction_type must be none, whitelist, or blacklist."
  }
}

variable "logging" {
  description = "Optional CloudFront standard logging config. Bucket must accept CloudFront log delivery."
  type = object({
    bucket          = string
    prefix          = optional(string, null)
    include_cookies = optional(bool, false)
  })
  default = null
}

variable "cache_policy" {
  description = "CloudFront cache policy parameters. Defaults forward nothing in the cache key (good for fully static SPA bundles where filenames are content-hashed)."
  type = object({
    min_ttl                       = optional(number, 0)
    default_ttl                   = optional(number, 86400)
    max_ttl                       = optional(number, 31536000)
    enable_accept_encoding_brotli = optional(bool, true)
    enable_accept_encoding_gzip   = optional(bool, true)
    cookie_behavior               = optional(string, "none")
    cookies                       = optional(list(string), [])
    header_behavior               = optional(string, "none")
    headers                       = optional(list(string), [])
    query_string_behavior         = optional(string, "none")
    query_strings                 = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = contains(["none", "whitelist", "allExcept", "all"], var.cache_policy.cookie_behavior)
    error_message = "cache_policy.cookie_behavior must be none, whitelist, allExcept, or all."
  }

  validation {
    condition     = contains(["none", "whitelist"], var.cache_policy.header_behavior)
    error_message = "cache_policy.header_behavior must be none or whitelist."
  }

  validation {
    condition     = contains(["none", "whitelist", "allExcept", "all"], var.cache_policy.query_string_behavior)
    error_message = "cache_policy.query_string_behavior must be none, whitelist, allExcept, or all."
  }
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
