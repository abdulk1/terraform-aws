data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  base_repo_name        = "${var.name_prefix}/base"
  app_nonprod_repo_name = "${var.name_prefix}/app/nonprod"

  repositories = {
    base        = local.base_repo_name
    app_nonprod = local.app_nonprod_repo_name
  }

  default_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the most recent 100 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 100
        }
        action = { type = "expire" }
      },
    ]
  })

  effective_lifecycle_policy = var.lifecycle_policy_enabled ? coalesce(var.lifecycle_policy_json, local.default_lifecycle_policy) : null

  arn_prefix = "arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository"

  # Wildcard ARNs cover any nested repository created under either prefix
  # (e.g. ${name_prefix}/base/python, ${name_prefix}/app/nonprod/api). The
  # literal ARNs cover pushes to the two root repositories themselves.
  scoped_repository_arns = [
    "${local.arn_prefix}/${local.base_repo_name}",
    "${local.arn_prefix}/${local.base_repo_name}/*",
    "${local.arn_prefix}/${local.app_nonprod_repo_name}",
    "${local.arn_prefix}/${local.app_nonprod_repo_name}/*",
  ]
}

resource "aws_ecr_repository" "this" {
  for_each = local.repositories

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.encryption_type != "KMS" || var.kms_key_arn != null
      error_message = "kms_key_arn is required when encryption_type is KMS."
    }
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.lifecycle_policy_enabled ? local.repositories : {}

  repository = aws_ecr_repository.this[each.key].name
  policy     = local.effective_lifecycle_policy
}

# Apply the same defaults to repositories AWS auto-creates under each prefix
# via pull-through cache rules or replication. Manual ecr:CreateRepository
# calls do not inherit these defaults; CI/CD pipelines that pre-create repos
# should set their own configuration.
resource "aws_ecr_repository_creation_template" "this" {
  for_each = local.repositories

  prefix               = each.value
  description          = "Defaults for ECR repositories created under ${each.value}/"
  applied_for          = ["PULL_THROUGH_CACHE", "REPLICATION"]
  image_tag_mutability = var.image_tag_mutability

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  lifecycle_policy = local.effective_lifecycle_policy

  resource_tags = var.tags
}

# Managed IAM policy granting account principals create/push/pull on both
# root repositories and any nested repository under each prefix. Same-account
# access still requires IAM grants like this one, so the repository resource
# policy is intentionally left unset.
data "aws_iam_policy_document" "push_pull" {
  statement {
    sid       = "GetAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushPullScoped"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:CreateRepository",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:PutLifecyclePolicy",
      "ecr:TagResource",
      "ecr:UploadLayerPart",
    ]
    resources = local.scoped_repository_arns
  }
}

resource "aws_iam_policy" "push_pull" {
  name        = "${var.name_prefix}-ecr-push-pull"
  description = "Create/push/pull access to ECR repositories ${local.base_repo_name}(/*) and ${local.app_nonprod_repo_name}(/*)."
  policy      = data.aws_iam_policy_document.push_pull.json
  tags        = var.tags
}
