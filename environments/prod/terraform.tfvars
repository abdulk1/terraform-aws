project_name = "enterprise-webapp"
environment  = "prod"
aws_region   = "us-east-1"

vpc_cidr = "10.30.0.0/16"
az_count = 3

kubernetes_version   = "1.35"
auto_mode_node_pools = ["system", "general-purpose"]

enable_cluster_creator_admin_permissions = true
cluster_admin_principal_arns             = []
cluster_viewer_principal_arns            = []

cluster_log_retention_days  = 365
enable_vpc_flow_logs        = true
vpc_flow_log_retention_days = 365

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

deletion_protection  = true
upgrade_support_type = "STANDARD"
enable_zonal_shift   = true

# Internal ALB that fronts EKS workloads. HTTPS-only in prod; flip
# enable_internal_alb to true once internal_alb_certificate_arn is set.
enable_internal_alb              = false
internal_alb_listener_protocol   = "HTTPS"
internal_alb_listener_port       = 443
internal_alb_certificate_arn     = null
internal_alb_deletion_protection = true

# External ALB inputs (used only when enable_internal_alb = false).
internal_alb_listener_arn      = null
internal_alb_security_group_id = null

enable_http_api_gateway            = false
http_api_authorization_type        = "AWS_IAM"
http_api_access_log_retention_days = 365

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

tags = {
  CostCenter = "platform"
  Workload   = "web"
}
