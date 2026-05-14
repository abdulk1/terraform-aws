resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/aws/apigateway/${var.name_prefix}-http-api"
  retention_in_days = var.http_api_access_log_retention_days
  kms_key_id        = var.http_api_access_log_kms_key_id

  tags = var.tags
}
