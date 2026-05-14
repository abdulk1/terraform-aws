locals {
  cluster_admin_access_entries = {
    for index, principal_arn in var.cluster_admin_principal_arns : "admin_${index}" => {
      principal_arn = principal_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  cluster_viewer_access_entries = {
    for index, principal_arn in var.cluster_viewer_principal_arns : "viewer_${index}" => {
      principal_arn = principal_arn
      policy_associations = {
        view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  control_plane_scaling_config = var.control_plane_scaling_tier == null ? null : {
    tier = var.control_plane_scaling_tier
  }

  zonal_shift_config = var.enable_zonal_shift ? {
    enabled = true
  } : null
}
