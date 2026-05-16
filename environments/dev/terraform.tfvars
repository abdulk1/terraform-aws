project_name = "hive-mvp"
environment  = "dev"
aws_region   = "us-east-1"

vpc_cidr = "10.10.0.0/16"
az_count = 3

kubernetes_version   = "1.35"
auto_mode_node_pools = ["system", "general-purpose"]

enable_cluster_creator_admin_permissions = true
cluster_admin_principal_arns             = []
cluster_viewer_principal_arns            = []

cluster_log_retention_days  = 30
enable_vpc_flow_logs        = true
vpc_flow_log_retention_days = 30

# EKS Auto Mode includes the Pod Identity Agent. Install the GuardDuty runtime
# monitoring agent as an EKS add-on; GuardDuty Runtime Monitoring must also be
# enabled in the account.
enable_guardduty_agent_addon               = true
guardduty_agent_addon_version              = null
guardduty_agent_addon_configuration_values = null

# AWS Secrets Store CSI Driver provider for mounting Secrets Manager secrets and
# SSM parameters as pod files. Workloads still need Pod Identity associations
# granting access to their specific secret ARNs.
enable_secrets_store_csi_driver_provider_addon               = true
secrets_store_csi_driver_provider_addon_version              = null
secrets_store_csi_driver_provider_addon_configuration_values = null

deletion_protection  = false
upgrade_support_type = "STANDARD"
enable_zonal_shift   = true

# Internal ALB that fronts EKS workloads. Defaults to HTTP on 80 for dev so it
# stands up without an ACM cert. Switch to HTTPS once a cert is available.
enable_internal_alb              = true
internal_alb_listener_protocol   = "HTTP"
internal_alb_listener_port       = 80
internal_alb_certificate_arn     = null
internal_alb_deletion_protection = false

# External ALB inputs (used only when enable_internal_alb = false).
internal_alb_listener_arn      = null
internal_alb_security_group_id = null

enable_http_api_gateway            = true
http_api_access_log_retention_days = 30

# Routes forwarded to the internal ALB. Each entry is "<METHOD> <PATH>".
http_api_route_keys = [
  "GET /{proxy+}",
  "POST /{proxy+}",
]

# JWT authorizer. Off until a real IdP is wired up — falls back to AWS_IAM auth.
# To turn on: uncomment and fill issuer/audience (Cognito user pool URL, Okta
# issuer, Auth0 tenant, etc.). Setting the object auto-flips auth type to JWT.
http_api_authorization_type = "AWS_IAM"
# http_api_jwt_authorizer = {
#   name             = "platform-jwt"
#   issuer           = "https://REPLACE-ME.example.com/oauth2/default"
#   audience         = ["hive-mvp-dev"]
#   identity_sources = ["$request.header.Authorization"]
# }

# CORS. allow_credentials = true requires explicit origins (no "*").
http_api_cors = {
  allow_credentials = true
  allow_origins     = ["https://app.dev.example.com"]
  allow_methods     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
  allow_headers     = ["Authorization", "Content-Type", "X-Requested-With"]
  expose_headers    = ["X-Request-Id"]
  max_age           = 600
}

# EKS-managed Argo CD capability. Requires an IAM Identity Center instance
# and at least one ADMIN rbac mapping. See README "Argo CD" section.
enable_argocd_capability = false
# argocd_idc_instance_arn = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxxxx"
# argocd_idc_region       = "us-east-1"
# argocd_rbac_role_mappings = [
#   {
#     role = "ADMIN"
#     identities = [
#       { id = "<idc-group-id>", type = "SSO_GROUP" },
#     ]
#   },
# ]
# argocd_vpc_endpoint_ids                = []
# argocd_enable_secrets_manager_access   = false
# argocd_secrets_manager_secret_arns     = []
# argocd_enable_codeconnections_access   = false
# argocd_codeconnections_connection_arns = []
# argocd_enable_ecr_pull_access          = false
# argocd_ecr_repository_arns             = []

# CloudFront + private S3 distribution for the React SPA UI.
# Off by default. Flip to true when ready to host the UI. Aliases + ACM cert
# (in us-east-1) are optional — without them the distribution serves on its
# default *.cloudfront.net domain.
enable_cloudfront_spa = false
# cloudfront_spa_aliases             = ["app.dev.example.com"]
# cloudfront_spa_acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx"
# cloudfront_spa_web_acl_id          = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/example/xxxxxxxx"

# Cache policy attached to the default behavior. Defaults: forward nothing in
# the cache key (good for fully content-hashed SPA bundles); 1d default TTL,
# 1y max TTL, brotli + gzip on. Override here if the SPA needs query strings
# or specific headers in the cache key.
cloudfront_spa_cache_policy = {
  min_ttl                       = 0
  default_ttl                   = 86400
  max_ttl                       = 31536000
  enable_accept_encoding_brotli = true
  enable_accept_encoding_gzip   = true
  cookie_behavior               = "none"
  header_behavior               = "none"
  query_string_behavior         = "none"
}

tags = {
  CostCenter = "platform"
  Workload   = "web"
}
