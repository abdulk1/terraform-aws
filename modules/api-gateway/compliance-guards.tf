resource "terraform_data" "compliance_guards" {
  input = var.name_prefix

  lifecycle {
    precondition {
      condition     = local.http_api_authorization_type != "NONE"
      error_message = "HTTP API Gateway must use AWS_IAM, JWT, or CUSTOM authorization for this FISMA-aligned baseline."
    }

    precondition {
      condition     = !contains(["CUSTOM", "JWT"], local.http_api_authorization_type) || var.http_api_authorizer_id != null || var.http_api_jwt_authorizer != null
      error_message = "CUSTOM or JWT HTTP API authorization requires http_api_authorizer_id or http_api_jwt_authorizer."
    }
  }
}
