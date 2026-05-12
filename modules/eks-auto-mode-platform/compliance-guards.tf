resource "terraform_data" "compliance_guards" {
  input = local.cluster_name

  lifecycle {
    precondition {
      condition     = !var.endpoint_public_access || !contains(var.endpoint_public_access_cidrs, "0.0.0.0/0")
      error_message = "Do not expose the EKS public API endpoint to 0.0.0.0/0. Use private access or restricted corporate/VPN CIDRs."
    }

    precondition {
      condition     = !var.enable_http_api_gateway || local.http_api_authorization_type != "NONE"
      error_message = "HTTP API Gateway must use AWS_IAM, JWT, or CUSTOM authorization for this FISMA-aligned baseline."
    }

    precondition {
      condition     = !var.enable_http_api_gateway || !contains(["CUSTOM", "JWT"], local.http_api_authorization_type) || var.http_api_authorizer_id != null || var.http_api_jwt_authorizer != null
      error_message = "CUSTOM or JWT HTTP API authorization requires http_api_authorizer_id or http_api_jwt_authorizer."
    }
  }
}
