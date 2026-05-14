locals {
  http_api_authorization_type = var.http_api_jwt_authorizer != null ? "JWT" : var.http_api_authorization_type
}
