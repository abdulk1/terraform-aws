locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"

  default_tags = merge(
    {
      Environment            = var.environment
      ManagedBy              = "Terraform"
      Project                = var.project_name
      "eks:eks-cluster-name" = local.cluster_name
    },
    var.tags,
  )
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}
