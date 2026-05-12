locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"
  azs          = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, index)
  ]

  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, index + 100)
  ]

  common_tags = merge(
    var.tags,
    {
      Environment            = var.environment
      ManagedBy              = "Terraform"
      Project                = var.project_name
      "eks:eks-cluster-name" = local.cluster_name
    }
  )

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
