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

  tags = local.default_tags
}
