module "platform" {
  source = "../../modules/eks-auto-mode-platform"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway

  enable_public_load_balancer_subnet_tags = var.enable_public_load_balancer_subnet_tags

  kubernetes_version   = var.kubernetes_version
  auto_mode_node_pools = var.auto_mode_node_pools

  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  cluster_admin_principal_arns             = var.cluster_admin_principal_arns
  cluster_viewer_principal_arns            = var.cluster_viewer_principal_arns

  enabled_log_types          = var.enabled_log_types
  cluster_log_retention_days = var.cluster_log_retention_days

  enable_vpc_flow_logs            = var.enable_vpc_flow_logs
  vpc_flow_log_retention_days     = var.vpc_flow_log_retention_days
  vpc_flow_log_kms_key_id         = var.vpc_flow_log_kms_key_id
  kms_key_deletion_window_in_days = var.kms_key_deletion_window_in_days

  control_plane_scaling_tier = var.control_plane_scaling_tier
  deletion_protection        = var.deletion_protection
  upgrade_support_type       = var.upgrade_support_type
  enable_zonal_shift         = var.enable_zonal_shift

  enable_http_api_gateway                      = var.enable_http_api_gateway
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
  internal_alb_listener_arn                    = var.internal_alb_listener_arn
  internal_alb_security_group_id               = var.internal_alb_security_group_id
  internal_alb_listener_port                   = var.internal_alb_listener_port
  manage_internal_alb_security_group_rule      = var.manage_internal_alb_security_group_rule

  tags = local.default_tags
}
