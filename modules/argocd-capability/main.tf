data "aws_iam_policy_document" "capability_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["capabilities.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "capability" {
  name               = "${var.name_prefix}-argocd-capability"
  assume_role_policy = data.aws_iam_policy_document.capability_trust.json

  tags = var.tags
}

data "aws_iam_policy_document" "secrets_manager" {
  count = var.enable_secrets_manager_access ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = var.secrets_manager_secret_arns
  }
}

resource "aws_iam_role_policy" "secrets_manager" {
  count = var.enable_secrets_manager_access ? 1 : 0

  name   = "secrets-manager"
  role   = aws_iam_role.capability.id
  policy = data.aws_iam_policy_document.secrets_manager[0].json
}

data "aws_iam_policy_document" "codeconnections" {
  count = var.enable_codeconnections_access ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "codeconnections:UseConnection",
      "codeconnections:GetConnection",
    ]
    resources = var.codeconnections_connection_arns
  }
}

resource "aws_iam_role_policy" "codeconnections" {
  count = var.enable_codeconnections_access ? 1 : 0

  name   = "codeconnections"
  role   = aws_iam_role.capability.id
  policy = data.aws_iam_policy_document.codeconnections[0].json
}

data "aws_iam_policy_document" "ecr_pull" {
  count = var.enable_ecr_pull_access ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_role_policy" "ecr_pull" {
  count = var.enable_ecr_pull_access ? 1 : 0

  name   = "ecr-pull"
  role   = aws_iam_role.capability.id
  policy = data.aws_iam_policy_document.ecr_pull[0].json
}

# Grant the capability role permission to talk to the cluster. Without this
# the EKS-managed Argo CD service can authenticate to AWS but cannot deploy
# Application/AppProject manifests to the Kubernetes API.
resource "aws_eks_access_entry" "capability" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.capability.arn
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "capability" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.capability]
}

resource "aws_eks_capability" "argocd" {
  cluster_name              = var.cluster_name
  capability_name           = var.capability_name
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.capability.arn
  delete_propagation_policy = var.delete_propagation_policy

  configuration {
    argo_cd {
      namespace = var.namespace

      aws_idc {
        idc_instance_arn = var.idc_instance_arn
        idc_region       = var.idc_region
      }

      dynamic "network_access" {
        for_each = length(var.vpc_endpoint_ids) > 0 ? [1] : []

        content {
          vpce_ids = toset(var.vpc_endpoint_ids)
        }
      }

      dynamic "rbac_role_mapping" {
        for_each = var.rbac_role_mappings

        content {
          role = rbac_role_mapping.value.role

          dynamic "identity" {
            for_each = rbac_role_mapping.value.identities

            content {
              id   = identity.value.id
              type = identity.value.type
            }
          }
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(var.rbac_role_mappings) > 0
      error_message = "At least one rbac_role_mapping (typically ADMIN) is required to access Argo CD."
    }

    precondition {
      condition     = !var.enable_secrets_manager_access || length(var.secrets_manager_secret_arns) > 0
      error_message = "enable_secrets_manager_access requires secrets_manager_secret_arns to be set."
    }

    precondition {
      condition     = !var.enable_codeconnections_access || length(var.codeconnections_connection_arns) > 0
      error_message = "enable_codeconnections_access requires codeconnections_connection_arns to be set."
    }

    precondition {
      condition     = !var.enable_ecr_pull_access || length(var.ecr_repository_arns) > 0
      error_message = "enable_ecr_pull_access requires ecr_repository_arns to be set."
    }
  }

  depends_on = [aws_eks_access_policy_association.capability]
}
