# MCP Configuration

Use `mcp.example.json` as a starting point for local MCP clients.

Included servers:

- `hashicorp.terraform`: HashiCorp Terraform MCP Server for Terraform Registry/provider/module context.
- `awslabs.terraform`: AWS Terraform MCP Server for AWS Terraform best practices and security scanning workflow support.
- `awslabs.aws-api-readonly`: AWS API MCP Server configured for read-only operation.

Security defaults in this example:

- No automatic tool approval.
- AWS API MCP uses `READ_OPERATIONS_ONLY=true`.
- AWS API MCP requires mutation consent if the read-only setting is changed.
- AWS API MCP local file access is set to `no-access`.
- AWS API MCP telemetry is disabled.

Do not commit real tokens, AWS keys, or production write-profile names. Use short-lived credentials and least-privilege IAM roles.
