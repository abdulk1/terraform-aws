module "network" {
  source = "../../modules/network"

  name_prefix  = local.name_prefix
  cluster_name = local.cluster_name
  aws_region   = var.aws_region

  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_vpc_flow_logs        = var.enable_vpc_flow_logs
  vpc_flow_log_retention_days = var.vpc_flow_log_retention_days
  vpc_flow_log_kms_key_id     = var.vpc_flow_log_kms_key_id

  tags = local.default_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = local.cluster_name
  aws_region   = var.aws_region

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  kubernetes_version   = var.kubernetes_version
  auto_mode_node_pools = var.auto_mode_node_pools

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  cluster_admin_principal_arns             = var.cluster_admin_principal_arns
  cluster_viewer_principal_arns            = var.cluster_viewer_principal_arns

  enabled_log_types               = var.enabled_log_types
  cluster_log_retention_days      = var.cluster_log_retention_days
  kms_key_deletion_window_in_days = var.kms_key_deletion_window_in_days

  control_plane_scaling_tier = var.control_plane_scaling_tier
  deletion_protection        = var.deletion_protection
  upgrade_support_type       = var.upgrade_support_type
  enable_zonal_shift         = var.enable_zonal_shift

  tags = local.default_tags
}

module "api_gateway" {
  count  = var.enable_http_api_gateway ? 1 : 0
  source = "../../modules/api-gateway"

  name_prefix = local.name_prefix

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  internal_alb_listener_arn               = var.internal_alb_listener_arn
  internal_alb_security_group_id          = var.internal_alb_security_group_id
  internal_alb_listener_port              = var.internal_alb_listener_port
  manage_internal_alb_security_group_rule = var.manage_internal_alb_security_group_rule

  http_api_name                                = var.http_api_name
  http_api_stage_name                          = var.http_api_stage_name
  http_api_route_keys                          = var.http_api_route_keys
  http_api_integration_method                  = var.http_api_integration_method
  http_api_request_parameter_mapping           = var.http_api_request_parameter_mapping
  http_api_timeout_milliseconds                = var.http_api_timeout_milliseconds
  http_api_disable_execute_api_endpoint        = var.http_api_disable_execute_api_endpoint
  http_api_authorization_type                  = var.http_api_authorization_type
  http_api_authorizer_id                       = var.http_api_authorizer_id
  http_api_jwt_authorizer                      = var.http_api_jwt_authorizer
  http_api_private_integration_tls_server_name = var.http_api_private_integration_tls_server_name
  http_api_access_log_retention_days           = var.http_api_access_log_retention_days
  http_api_access_log_kms_key_id               = var.http_api_access_log_kms_key_id

  tags = local.default_tags
}

module "argocd_capability" {
  count  = var.enable_argocd_capability ? 1 : 0
  source = "../../modules/argocd-capability"

  name_prefix     = local.name_prefix
  cluster_name    = module.eks.cluster_name
  capability_name = var.argocd_capability_name

  idc_instance_arn   = var.argocd_idc_instance_arn
  idc_region         = var.argocd_idc_region
  rbac_role_mappings = var.argocd_rbac_role_mappings

  vpc_endpoint_ids          = var.argocd_vpc_endpoint_ids
  delete_propagation_policy = var.argocd_delete_propagation_policy

  enable_secrets_manager_access   = var.argocd_enable_secrets_manager_access
  secrets_manager_secret_arns     = var.argocd_secrets_manager_secret_arns
  enable_codeconnections_access   = var.argocd_enable_codeconnections_access
  codeconnections_connection_arns = var.argocd_codeconnections_connection_arns

  tags = local.default_tags
}
