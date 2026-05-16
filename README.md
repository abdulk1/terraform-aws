# Enterprise AWS EKS Auto Mode Terraform

This repository provisions an AWS foundation for an enterprise web application across separate `dev`, `test`, and `prod` environments.

It creates:

- A dedicated, fully private VPC per environment across 3 Availability Zones (no NAT gateway, no internet gateway, no public subnets).
- Private subnets for EKS Auto Mode nodes.
- VPC interface endpoints (and an S3 gateway endpoint) for the AWS services EKS Auto Mode and typical workloads need.
- Amazon EKS with Auto Mode compute enabled, private API endpoint only.
- Built-in EKS Auto Mode `system` and `general-purpose` node pools.
- EKS Auto Mode built-in Pod Identity Agent support.
- Amazon GuardDuty EKS Runtime Monitoring agent installed as the `aws-guardduty-agent` EKS add-on.
- AWS Secrets Store CSI Driver provider installed as the `aws-secrets-store-csi-driver-provider` EKS add-on for mounting Secrets Manager secrets into pods.
- EKS API authentication through access entries, not `aws-auth`.
- KMS-backed Kubernetes secret encryption.
- EKS control plane logs.
- VPC flow logs.
- An internal Application Load Balancer provisioned alongside EKS as the standing ingress, with a 404 fixed-response default listener that workloads attach to via `TargetGroupBinding` (HTTP or HTTPS, configurable per environment).
- Optional API Gateway HTTP API with VPC Link private integration to the internal ALB, supporting route keys, JWT or AWS_IAM authorization, and CORS.
- Optional CloudFront + private S3 distribution for hosting a React single-page application UI, with Origin Access Control, SPA routing rewrites, and a custom cache policy.
- IRSA OIDC provider for workloads that still use IAM roles for service accounts.

## Repository Layout

```text
.
├── environments/
│   ├── dev/
│   ├── test/
│   └── prod/
├── docs/
├── examples/
│   └── kubernetes/
├── modules/
│   ├── network/
│   ├── eks/
│   ├── internal-alb/
│   ├── api-gateway/
│   ├── cloudfront-spa/
│   └── argocd-capability/
├── Makefile
└── README.md
```

Each environment is a separate Terraform root module. This keeps state, blast radius, and approvals isolated by environment.

## EKS Auto Mode Notes

EKS Auto Mode requires the compute, load balancing, and block storage capabilities to be enabled together. The `terraform-aws-modules/eks/aws` module configures those capabilities from `compute_config` and disables self-managed add-on bootstrapping for the cluster resource.

The module also creates the Auto Mode cluster IAM policies and the Auto Mode node IAM role. AWS requires the node role to be separate from the cluster role.

EKS Auto Mode includes the Pod Identity Agent by default, so this stack does not create a separate `eks-pod-identity-agent` add-on. The EKS module does install the GuardDuty runtime monitoring agent as the `aws-guardduty-agent` add-on by default. GuardDuty Runtime Monitoring still needs to be enabled at the AWS account/organization level for the agent to produce findings.

The EKS module also installs the AWS Secrets Store CSI Driver provider add-on (`aws-secrets-store-csi-driver-provider`) so workloads can mount AWS Secrets Manager secrets and Systems Manager Parameter Store parameters as files. Workloads still need Pod Identity associations and least-privilege IAM permissions for their specific secret ARNs. A sample `SecretProviderClass` and volume mount is in [examples/kubernetes/app/sample-secret-provider-class.yaml](./examples/kubernetes/app/sample-secret-provider-class.yaml).

References:

- [AWS EKS Auto Mode cluster IAM role](https://docs.aws.amazon.com/eks/latest/userguide/auto-cluster-iam-role.html)
- [AWS EKS Auto Mode node IAM role](https://docs.aws.amazon.com/eks/latest/userguide/auto-create-node-role.html)
- [AWS EKS Pod Identity Agent setup](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html)
- [AWS EKS available add-ons](https://docs.aws.amazon.com/eks/latest/userguide/workloads-add-ons-available-eks.html)
- [AWS Secrets Manager with EKS Pods](https://docs.aws.amazon.com/eks/latest/userguide/manage-secrets.html)
- [AWS Secrets Store CSI provider with Pod Identity](https://docs.aws.amazon.com/secretsmanager/latest/userguide/ascp-pod-identity-integration.html)
- [AWS GuardDuty Runtime Monitoring for EKS](https://docs.aws.amazon.com/guardduty/latest/ug/how-runtime-monitoring-works-eks.html)
- [AWS built-in Auto Mode node pools](https://docs.aws.amazon.com/eks/latest/userguide/set-builtin-node-pools.html)
- [AWS EKS Auto Mode ALB IngressClassParams](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-alb.html)
- [Terraform AWS provider EKS Auto Mode arguments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
- [terraform-aws-modules/eks Auto Mode example](https://github.com/terraform-aws-modules/terraform-aws-eks#eks-auto-mode)

## Private Ingress

The intended ingress path is:

```text
Client -> API Gateway HTTP API -> VPC Link -> internal ALB -> EKS service
```

There are no public subnets and no internet gateway in this VPC, so internet-facing Kubernetes load balancers cannot be provisioned. Private subnets remain tagged for internal load balancers (`kubernetes.io/role/internal-elb`).

### Internal ALB

The internal ALB is provisioned by the [`internal-alb`](./modules/internal-alb) module, gated per environment by `enable_internal_alb`. When enabled it creates:

- An internal Application Load Balancer across all private subnets.
- A dedicated security group. Other in-VPC consumers (API Gateway VPC Link ENIs, pod security groups) are granted ingress via `ingress_security_group_ids`; CIDR ingress is opt-in via `ingress_cidr_blocks`.
- A default listener with a `fixed-response 404` default action. Workloads attach target groups to this listener via Kubernetes `TargetGroupBinding` CRs, which the AWS Load Balancer Controller (bundled with EKS Auto Mode) reconciles. This keeps the ALB stable across pod churn and avoids one ALB per `Ingress`.

Default listener protocol is `HTTPS` on port `443` and requires `internal_alb_certificate_arn` to be set to an ACM certificate ARN. AWS does **not** ship a managed certificate on the `*.elb.amazonaws.com` DNS name — any HTTPS listener needs your cert in ACM. For dev convenience the `dev` environment ships with `HTTP` on port `80` so the ALB stands up without a cert prerequisite.

Outputs surfaced per environment: `internal_alb_arn`, `internal_alb_dns_name`, `internal_alb_zone_id`, `internal_alb_listener_arn`, `internal_alb_security_group_id`.

Existing externally provisioned ALBs are still supported — leave `enable_internal_alb = false` and pass `internal_alb_listener_arn` / `internal_alb_security_group_id` directly. The API Gateway module picks the module-created ALB when available and falls back to the externally provisioned inputs otherwise.

Ingress manifests are split into platform-owned and app-owned files:

- Platform: [examples/kubernetes/platform/ingress-class-internal.yaml](./examples/kubernetes/platform/ingress-class-internal.yaml) — `IngressClass` + `IngressClassParams`.
- App: [examples/kubernetes/app/sample-ingress.yaml](./examples/kubernetes/app/sample-ingress.yaml) — per-workload `Ingress` (or `TargetGroupBinding`) referencing the shared internal ALB.

### API Gateway HTTP API

The [`api-gateway`](./modules/api-gateway) module is gated by `enable_http_api_gateway` and provisions an HTTP API with a VPC Link private integration to the internal ALB listener. When `enable_internal_alb = true`, the module's outputs flow into the API Gateway block automatically — no manual ARN plumbing.

Configurable settings (all live in `environments/<env>/terraform.tfvars`):

- **Routes** — `http_api_route_keys` defaults to `["ANY /", "ANY /{proxy+}"]`. Add explicit routes like `"POST /orders"`, `"GET /users/{id}"` as services come online.
- **Authorization** — `http_api_authorization_type` defaults to `AWS_IAM` (SigV4). To switch to JWT, set `http_api_jwt_authorizer` to an object with `name`, `issuer`, `audience`, and optional `identity_sources`; the module auto-flips the effective auth type to `JWT`. JWT requires the IdP's JWKS endpoint to be reachable from API Gateway (standard public IdPs work; private OIDC providers need extra routing).
- **CORS** — `http_api_cors` accepts `allow_origins`, `allow_methods`, `allow_headers`, `expose_headers`, `allow_credentials`, `max_age`. Default is `null` (CORS disabled). A validation rule rejects `allow_credentials = true` combined with `allow_origins = ["*"]`.
- **TLS to backend** — `http_api_private_integration_tls_server_name` overrides the SNI name API Gateway sends to the ALB listener when the listener uses HTTPS.
- **`execute-api` endpoint** — `http_api_disable_execute_api_endpoint` defaults to `false`. Disable after attaching a custom domain.

More detail is in [docs/private-ingress.md](./docs/private-ingress.md).

## React SPA UI (CloudFront + S3)

The [`cloudfront-spa`](./modules/cloudfront-spa) module provisions a CloudFront distribution that serves a React single-page application from a private S3 bucket. It is gated per environment by `enable_cloudfront_spa` (default `false`).

What the module creates:

- A private S3 bucket with `BucketOwnerEnforced` ownership, all public access blocked, versioning on, SSE-S3 (or KMS via `cloudfront_spa_kms_key_arn`), and a bucket policy that allows reads only from this distribution and denies non-TLS access.
- A CloudFront Origin Access Control (OAC, SigV4) — the modern replacement for Origin Access Identity.
- A CloudFront distribution with HTTPS-redirect, HTTP/2+3, IPv6, optional WAFv2 (`cloudfront_spa_web_acl_id`, must be CloudFront-scoped in `us-east-1`), optional geo restriction, and optional standard access logging.
- SPA routing: by default 403 and 404 origin responses are rewritten to `/index.html` with HTTP 200 so client-side routes resolve. Toggle with `cloudfront_spa_error_responses`.
- A custom `aws_cloudfront_cache_policy` attached to the default behavior. Configurable via the `cloudfront_spa_cache_policy` object:
  - `min_ttl` / `default_ttl` / `max_ttl` (defaults 0 / 1 day / 1 year)
  - `enable_accept_encoding_brotli`, `enable_accept_encoding_gzip` (both default `true`)
  - `cookie_behavior` + `cookies`, `header_behavior` + `headers`, `query_string_behavior` + `query_strings` for what enters the cache key and is forwarded to origin. Defaults forward nothing — best for fully content-hashed SPA bundles.

Custom domains are optional. To attach one, set both `cloudfront_spa_aliases` and `cloudfront_spa_acm_certificate_arn` (the ACM certificate **must** be issued in `us-east-1`). Without those the distribution serves on its default `*.cloudfront.net` domain.

Outputs per environment: `cloudfront_spa_bucket_name`, `cloudfront_spa_distribution_id`, `cloudfront_spa_distribution_domain_name`, `cloudfront_spa_distribution_hosted_zone_id`, `cloudfront_spa_cache_policy_id`.

Typical deploy workflow once the stack is applied:

```sh
# Sync the built React bundle.
aws s3 sync ./dist s3://$(terraform -chdir=environments/dev output -raw cloudfront_spa_bucket_name)/ --delete

# Invalidate the distribution so users see the new bundle immediately.
aws cloudfront create-invalidation \
  --distribution-id $(terraform -chdir=environments/dev output -raw cloudfront_spa_distribution_id) \
  --paths "/*"
```

## FISMA Posture

This repo is configured with FISMA-aligned defaults for the workload infrastructure, but FISMA compliance is not created by Terraform alone. Compliance requires full system boundary definition, account-level controls, continuous monitoring, documentation, assessment, and agency authorization.

At minimum, pair this stack with centralized CloudTrail, AWS Config, Security Hub, GuardDuty, vulnerability management, least-privilege IAM, approved CI/CD, audit evidence retention, and an ATO package. See [docs/fisma-compliance.md](./docs/fisma-compliance.md).

## Prerequisites

- Terraform `>= 1.5.7`; `.terraform-version` pins `1.14.6`, which was used to validate this repo.
- AWS provider `>= 6.28, < 7.0`.
- AWS CLI configured for the target account.
- IAM permissions to create VPC, EKS, IAM, KMS, CloudWatch Logs, and EC2 networking resources.
- `kubectl` for cluster access after provisioning.

## Remote State

Each environment includes a `backend.tf.example`. Before running Terraform in a shared account, copy it to `backend.tf` and replace the bucket name:

```sh
cp environments/dev/backend.tf.example environments/dev/backend.tf
```

Use one encrypted, versioned S3 state bucket per AWS account or per organization security boundary. The example uses S3 native locking:

```hcl
use_lockfile = true
```

If your Terraform version is older than 1.10, use a DynamoDB lock table instead of `use_lockfile`.

## Configure Environments

Review each `terraform.tfvars` file before deployment:

- `environments/dev/terraform.tfvars`
- `environments/test/terraform.tfvars`
- `environments/prod/terraform.tfvars`

Important values to change:

- `project_name`
- `aws_region`
- `vpc_cidr`
- `cluster_admin_principal_arns`
- `cluster_viewer_principal_arns`
- `enable_internal_alb`, `internal_alb_listener_protocol`, `internal_alb_listener_port`, `internal_alb_certificate_arn` (required for HTTPS), `internal_alb_deletion_protection`
- `enable_guardduty_agent_addon`, `guardduty_agent_addon_version`, `guardduty_agent_addon_configuration_values`, `additional_eks_addons`
- `enable_secrets_store_csi_driver_provider_addon`, `secrets_store_csi_driver_provider_addon_version`, `secrets_store_csi_driver_provider_addon_configuration_values`
- `enable_http_api_gateway`
- `http_api_route_keys`
- `http_api_authorization_type` or `http_api_jwt_authorizer`
- `http_api_cors`
- `enable_cloudfront_spa`, `cloudfront_spa_aliases`, `cloudfront_spa_acm_certificate_arn` (cert must be in `us-east-1`), `cloudfront_spa_web_acl_id`, `cloudfront_spa_cache_policy`
- `tags`

When `enable_internal_alb = true`, the ALB outputs are wired into the API Gateway module automatically. When `false`, supply your own ALB via `internal_alb_listener_arn` and `internal_alb_security_group_id`.

The EKS API endpoint is hard-wired to private-only and cannot be exposed publicly from this module. Reach the cluster from a network path that lands inside the VPC (VPN, Direct Connect, bastion, or a private runner).

For production, set `deletion_protection = true` to protect the EKS cluster.

## Deploy

Run all commands from the repository root.

Initialize an environment:

```sh
make init ENV=dev
```

Format and validate:

```sh
make fmt
make validate ENV=dev
```

Run a Terraform security scan when Checkov is installed:

```sh
make security-scan ENV=dev
```

Plan and apply:

```sh
make plan ENV=dev
make apply ENV=dev
```

Repeat for `test` and `prod`:

```sh
make init ENV=test
make plan ENV=test
make apply ENV=test

make init ENV=prod
make plan ENV=prod
make apply ENV=prod
```

## Configure Kubectl

After apply:

```sh
terraform -chdir=environments/dev output configure_kubectl
aws eks update-kubeconfig --region us-east-1 --name enterprise-webapp-dev-eks
kubectl get nodes
```

If the endpoint is private only, run `kubectl` from a network path that can reach the VPC, such as VPN, Direct Connect, a bastion, or a private runner.

## Access Model

The stack uses EKS access entries. During initial bootstrap, `enable_cluster_creator_admin_permissions = true` grants the Terraform caller admin access.

For steady state, prefer explicit IAM roles:

```hcl
cluster_admin_principal_arns = [
  "arn:aws:iam::123456789012:role/platform-admin",
]

cluster_viewer_principal_arns = [
  "arn:aws:iam::123456789012:role/developer-readonly",
]
```

After explicit admin roles are verified, set `enable_cluster_creator_admin_permissions = false`.

## Application Deployment

This repository provisions the AWS/EKS platform. Application delivery should be added as a separate layer, usually one of:

- Helm releases from a GitOps controller such as Argo CD or Flux.
- A separate Terraform workspace/module for platform add-ons.
- CI/CD jobs that deploy Kubernetes manifests after the cluster exists.

Use Kubernetes service annotations or Gateway/Ingress resources to request AWS load balancers. Private subnets are tagged for internal AWS load balancer discovery.

For this architecture, use internal ALBs only. The VPC has no internet gateway or public subnets, so internet-facing Kubernetes load balancers cannot be provisioned by design.

## Argo CD (EKS Managed Capability)

EKS Auto Mode supports a fully AWS-managed Argo CD via the `aws_eks_capability` resource. This stack wraps it in [modules/argocd-capability](./modules/argocd-capability) and wires it into each environment behind `enable_argocd_capability` (default `false`).

Prerequisites:

- An AWS IAM Identity Center instance in the same organization (local Argo CD users are not supported).
- The Identity Center group/user IDs to grant Argo CD `ADMIN` (look them up with `aws identitystore list-groups --identity-store-id <id>`).
- The cluster must already be applied — the capability attaches to an existing cluster.

To enable, set the following in `environments/<env>/terraform.tfvars`:

```hcl
enable_argocd_capability = true
argocd_idc_instance_arn  = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxxxx"
argocd_idc_region        = "us-east-1" # omit to default to aws_region

argocd_rbac_role_mappings = [
  {
    role = "ADMIN"
    identities = [
      { id = "<idc-group-id>", type = "SSO_GROUP" },
    ]
  },
]
```

Optional toggles (all default off / empty):

- `argocd_capability_name`, `argocd_delete_propagation_policy` — capability naming and CRD retention on delete.
- `argocd_vpc_endpoint_ids` — restrict UI/API access to specific VPC endpoints for private-only reach.
- `argocd_enable_secrets_manager_access` + `argocd_secrets_manager_secret_arns` — Argo CD reads Git credentials from Secrets Manager.
- `argocd_enable_codeconnections_access` + `argocd_codeconnections_connection_arns` — Argo CD authenticates to Git via AWS CodeConnections.
- `argocd_enable_ecr_pull_access` + `argocd_ecr_repository_arns` — Argo CD pulls OCI Helm charts or manifests from ECR.

What the module does for you:

- Creates the capability IAM role with the `capabilities.eks.amazonaws.com` trust policy.
- Creates an EKS access entry + cluster-admin access policy association for that role, so Argo CD can actually deploy to the cluster.
- Registers the capability with EKS (including IdC integration and any RBAC role mappings).
- Adds the scoped IAM policies for the optional integrations above.

Post-apply (one-time, per cluster):

1. Read `terraform output argocd_server_url` for the managed Argo CD UI.
2. Register the cluster as an Argo CD deployment target by applying the cluster-secret manifest documented in [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/argocd-add-cluster.html). This is a `kubectl apply` step and is intentionally not Terraform-managed.
3. Sign in via your IAM Identity Center group mapped to `ADMIN`.

References:

- [AWS EKS managed Argo CD capability](https://docs.aws.amazon.com/eks/latest/userguide/argocd.html)
- [Terraform `aws_eks_capability`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_capability)

## Destroy

Destroy non-production environments only after removing application load balancers and persistent volumes:

```sh
make destroy ENV=dev
```

For prod, first set:

```hcl
deletion_protection = false
```

Apply that change, then run destroy.
