resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name              = "/aws/vpc-flow-logs/${var.name_prefix}"
  retention_in_days = var.vpc_flow_log_retention_days
  kms_key_id        = var.vpc_flow_log_kms_key_id

  tags = var.tags
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name               = "${var.name_prefix}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume_role[0].json

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name   = "${var.name_prefix}-vpc-flow-logs"
  role   = aws_iam_role.vpc_flow_logs[0].id
  policy = data.aws_iam_policy_document.vpc_flow_logs[0].json
}

resource "aws_flow_log" "this" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id

  max_aggregation_interval = 60

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc-flow-logs"
    }
  )

  depends_on = [
    aws_iam_role_policy.vpc_flow_logs,
  ]
}
