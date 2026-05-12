# FISMA Compliance Notes

This Terraform is configured to support a FISMA-aligned AWS deployment, but Terraform code alone cannot make a system FISMA compliant. FISMA authorization depends on the full system boundary, control implementation, continuous monitoring, documentation, assessment, and agency Authorizing Official approval.

## Platform Controls In This Repo

- EKS API endpoint is private by default.
- Kubernetes authentication uses EKS access entries instead of the legacy `aws-auth` ConfigMap.
- EKS control plane audit, API, authenticator, controller manager, and scheduler logs are enabled.
- Kubernetes secret encryption uses a customer-managed KMS key with rotation enabled.
- VPC flow logs are enabled.
- Public subnet tagging for internet-facing Kubernetes load balancers is disabled by default.
- Private ALB ingress is modeled through EKS Auto Mode `IngressClassParams` with `scheme: internal`.
- API Gateway HTTP API integration uses VPC Link to reach the private ALB listener.
- HTTP API access logs are enabled when the HTTP API is enabled.
- HTTP API routes default to `AWS_IAM` authorization unless a JWT authorizer is configured.
- Production defaults enable EKS deletion protection and one NAT gateway per AZ.

## Required Controls Outside This Module

Implement these at the AWS account, organization, CI/CD, and application layers before claiming compliance:

- Confirm the chosen AWS partition, regions, and services are in the required FedRAMP/FISMA authorization scope for the workload impact level.
- Use AWS Organizations with SCP guardrails, centralized logging, and separation of duties.
- Enable organization-level CloudTrail, AWS Config, Security Hub, GuardDuty, Inspector, IAM Access Analyzer, and vulnerability management.
- Store Terraform state in an encrypted, versioned S3 bucket with least-privilege access and state locking.
- Enforce MFA, short-lived credentials, privileged access review, and break-glass procedures.
- Use approved CI/CD pipelines with change control, code review, signed artifacts where required, and evidence retention.
- Attach API Gateway custom domains and authorizers appropriate to the application user population.
- Use TLS for API Gateway to ALB private integration by setting `http_api_private_integration_tls_server_name` and using an HTTPS ALB listener.
- Define backup, incident response, contingency planning, media protection, audit log retention, vulnerability remediation, and POA&M processes.
- Maintain SSP, control implementation statements, inherited/shared/customer responsibility mapping, SAR, continuous monitoring evidence, and ATO package artifacts.

## MCP Guidance

The MCP examples are for local development assistance only. Do not run MCP servers with production write credentials. For FISMA-aligned work:

- Prefer read-only AWS MCP profiles.
- Keep `READ_OPERATIONS_ONLY=true` for AWS API MCP unless an approved change window requires mutations.
- Keep `REQUIRE_MUTATION_CONSENT=true`.
- Restrict local file access to `no-access` or a dedicated work directory.
- Run MCP servers locally over STDIO or localhost only.
- Do not store credentials or tokens in committed MCP config files.

## References

- AWS FISMA overview: https://aws.amazon.com/compliance/fisma/
- AWS FedRAMP overview: https://aws.amazon.com/govcloud-us/fedramp/
- AWS Artifact: https://docs.aws.amazon.com/console/artifact
- AWS FedRAMP Rev5 secure configuration guidance: https://docs.aws.amazon.com/fedramp/latest/userguide/introduction.html
- FedRAMP and FISMA relationship: https://help.fedramp.gov/hc/en-us/articles/27700916142747-What-is-the-difference-between-Federal-Information-Security-Modernization-Act-FISMA-and-FedRAMP-controls
