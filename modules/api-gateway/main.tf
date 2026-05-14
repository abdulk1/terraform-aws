resource "aws_apigatewayv2_api" "http" {
  name                         = coalesce(var.http_api_name, "${var.name_prefix}-http-api")
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = var.http_api_disable_execute_api_endpoint

  tags = var.tags
}

resource "aws_apigatewayv2_vpc_link" "http" {
  name               = "${var.name_prefix}-http-api-vpc-link"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = var.subnet_ids

  tags = var.tags
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.http_api_jwt_authorizer != null ? 1 : 0

  api_id           = aws_apigatewayv2_api.http.id
  authorizer_type  = "JWT"
  identity_sources = var.http_api_jwt_authorizer.identity_sources
  name             = var.http_api_jwt_authorizer.name

  jwt_configuration {
    audience = var.http_api_jwt_authorizer.audience
    issuer   = var.http_api_jwt_authorizer.issuer
  }
}

resource "aws_apigatewayv2_integration" "private_alb" {
  api_id                 = aws_apigatewayv2_api.http.id
  connection_id          = aws_apigatewayv2_vpc_link.http.id
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
  for_each = toset(var.http_api_route_keys)

  api_id             = aws_apigatewayv2_api.http.id
  route_key          = each.value
  target             = "integrations/${aws_apigatewayv2_integration.private_alb.id}"
  authorization_type = local.http_api_authorization_type
  authorizer_id      = local.http_api_authorization_type == "JWT" ? coalesce(try(aws_apigatewayv2_authorizer.jwt[0].id, null), var.http_api_authorizer_id) : var.http_api_authorizer_id
}

resource "aws_apigatewayv2_stage" "http" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.http_api_stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
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

  tags = var.tags
}
