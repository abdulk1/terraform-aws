resource "aws_cloudwatch_log_group" "http_api_access_logs" {
  count = var.enable_http_api_gateway ? 1 : 0

  name              = "/aws/apigateway/${local.name_prefix}-http-api"
  retention_in_days = var.http_api_access_log_retention_days
  kms_key_id        = var.http_api_access_log_kms_key_id

  tags = local.common_tags
}

resource "aws_security_group" "api_gateway_vpc_link" {
  count = var.enable_http_api_gateway ? 1 : 0

  name                   = "${local.name_prefix}-apigw-vpc-link"
  description            = "API Gateway HTTP API VPC Link egress to the private application ALB"
  vpc_id                 = module.vpc.vpc_id
  revoke_rules_on_delete = true

  egress {
    description     = "Allow API Gateway VPC Link traffic to the private ALB listener"
    from_port       = var.internal_alb_listener_port
    to_port         = var.internal_alb_listener_port
    protocol        = "tcp"
    security_groups = [var.internal_alb_security_group_id]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-apigw-vpc-link"
    }
  )

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.internal_alb_listener_arn != null && var.internal_alb_security_group_id != null
      error_message = "internal_alb_listener_arn and internal_alb_security_group_id are required when enable_http_api_gateway is true."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "internal_alb_from_api_gateway_vpc_link" {
  count = var.enable_http_api_gateway && var.manage_internal_alb_security_group_rule ? 1 : 0

  security_group_id            = var.internal_alb_security_group_id
  referenced_security_group_id = aws_security_group.api_gateway_vpc_link[0].id
  ip_protocol                  = "tcp"
  from_port                    = var.internal_alb_listener_port
  to_port                      = var.internal_alb_listener_port
  description                  = "Allow API Gateway VPC Link traffic to the private ALB listener"

  tags = local.common_tags
}

resource "aws_apigatewayv2_api" "http" {
  count = var.enable_http_api_gateway ? 1 : 0

  name                         = coalesce(var.http_api_name, "${local.name_prefix}-http-api")
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = var.http_api_disable_execute_api_endpoint

  tags = local.common_tags
}

resource "aws_apigatewayv2_vpc_link" "http" {
  count = var.enable_http_api_gateway ? 1 : 0

  name               = "${local.name_prefix}-http-api-vpc-link"
  security_group_ids = [aws_security_group.api_gateway_vpc_link[0].id]
  subnet_ids         = module.vpc.private_subnets

  tags = local.common_tags
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.enable_http_api_gateway && var.http_api_jwt_authorizer != null ? 1 : 0

  api_id           = aws_apigatewayv2_api.http[0].id
  authorizer_type  = "JWT"
  identity_sources = var.http_api_jwt_authorizer.identity_sources
  name             = var.http_api_jwt_authorizer.name

  jwt_configuration {
    audience = var.http_api_jwt_authorizer.audience
    issuer   = var.http_api_jwt_authorizer.issuer
  }
}

resource "aws_apigatewayv2_integration" "private_alb" {
  count = var.enable_http_api_gateway ? 1 : 0

  api_id                 = aws_apigatewayv2_api.http[0].id
  connection_id          = aws_apigatewayv2_vpc_link.http[0].id
  connection_type        = "VPC_LINK"
  integration_method     = var.http_api_integration_method
  integration_type       = "HTTP_PROXY"
  integration_uri        = var.internal_alb_listener_arn
  payload_format_version = "1.0"
  request_parameters     = var.http_api_request_parameter_mapping
  timeout_milliseconds   = var.http_api_timeout_milliseconds

  dynamic "tls_config" {
    for_each = var.http_api_private_integration_tls_server_name == null ? [] : [var.http_api_private_integration_tls_server_name]

    content {
      server_name_to_verify = tls_config.value
    }
  }
}

resource "aws_apigatewayv2_route" "private_alb" {
  for_each = var.enable_http_api_gateway ? toset(var.http_api_route_keys) : toset([])

  api_id             = aws_apigatewayv2_api.http[0].id
  route_key          = each.value
  target             = "integrations/${aws_apigatewayv2_integration.private_alb[0].id}"
  authorization_type = local.http_api_authorization_type
  authorizer_id      = local.http_api_authorization_type == "JWT" ? coalesce(try(aws_apigatewayv2_authorizer.jwt[0].id, null), var.http_api_authorizer_id) : var.http_api_authorizer_id
}

resource "aws_apigatewayv2_stage" "http" {
  count = var.enable_http_api_gateway ? 1 : 0

  api_id      = aws_apigatewayv2_api.http[0].id
  name        = var.http_api_stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.http_api_access_logs[0].arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      protocol           = "$context.protocol"
      responseLength     = "$context.responseLength"
      integrationError   = "$context.integrationErrorMessage"
      authorizerError    = "$context.authorizer.error"
      integrationLatency = "$context.integrationLatency"
    })
  }

  tags = local.common_tags
}
