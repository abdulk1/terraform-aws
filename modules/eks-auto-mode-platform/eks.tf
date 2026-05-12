module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.20.0"

  region = var.aws_region

  name               = local.cluster_name
  kubernetes_version = var.kubernetes_version

  authentication_mode = "API"
  access_entries = merge(
    local.cluster_admin_access_entries,
    local.cluster_viewer_access_entries,
  )
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  endpoint_private_access      = true
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  compute_config = {
    enabled    = true
    node_pools = var.auto_mode_node_pools
  }

  create_node_iam_role         = true
  enable_auto_mode_custom_tags = true
  enable_irsa                  = true

  create_kms_key                  = true
  enable_kms_key_rotation         = true
  kms_key_deletion_window_in_days = var.kms_key_deletion_window_in_days
  encryption_config = {
    resources = ["secrets"]
  }

  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_days
  enabled_log_types                      = var.enabled_log_types

  control_plane_scaling_config = local.control_plane_scaling_config
  deletion_protection          = var.deletion_protection
  upgrade_policy = {
    support_type = var.upgrade_support_type
  }
  zonal_shift_config = local.zonal_shift_config

  tags = local.common_tags
}
