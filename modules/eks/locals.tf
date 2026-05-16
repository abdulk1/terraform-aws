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

  guardduty_agent_addon = var.enable_guardduty_agent_addon ? {
    aws_guardduty_agent = {
      name                 = "aws-guardduty-agent"
      addon_version        = var.guardduty_agent_addon_version
      configuration_values = var.guardduty_agent_addon_configuration_values
      most_recent          = true
    }
  } : {}

  secrets_store_csi_driver_provider_addon = var.enable_secrets_store_csi_driver_provider_addon ? {
    aws_secrets_store_csi_driver_provider = {
      name                 = "aws-secrets-store-csi-driver-provider"
      addon_version        = var.secrets_store_csi_driver_provider_addon_version
      configuration_values = var.secrets_store_csi_driver_provider_addon_configuration_values
      most_recent          = true
    }
  } : {}

  cluster_addons = merge(
    local.guardduty_agent_addon,
    local.secrets_store_csi_driver_provider_addon,
    var.additional_eks_addons,
  )

  zonal_shift_config = var.enable_zonal_shift ? {
    enabled = true
  } : null
}
