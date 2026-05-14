# Enterprise AWS EKS Auto Mode Terraform

This repository provisions an AWS foundation for an enterprise web application across separate `dev`, `test`, and `prod` environments.

It creates:

- A dedicated, fully private VPC per environment across 3 Availability Zones (no NAT gateway, no internet gateway, no public subnets).
- Private subnets for EKS Auto Mode nodes.
- VPC interface endpoints (and an S3 gateway endpoint) for the AWS services EKS Auto Mode and typical workloads need.
- Amazon EKS with Auto Mode compute enabled, private API endpoint only.
- Built-in EKS Auto Mode `system` and `general-purpose` node pools.
- EKS API authentication through access entries, not `aws-auth`.
- KMS-backed Kubernetes secret encryption.
- EKS control plane logs.
- VPC flow logs.
- Private/internal ALB discovery for Kubernetes ingress.
- Optional API Gateway HTTP API with VPC Link private integration to an internal ALB listener.
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
│   └── api-gateway/
├── Makefile
└── README.md
```

Each environment is a separate Terraform root module. This keeps state, blast radius, and approvals isolated by environment.

## EKS Auto Mode Notes

EKS Auto Mode requires the compute, load balancing, and block storage capabilities to be enabled together. The `terraform-aws-modules/eks/aws` module configures those capabilities from `compute_config` and disables self-managed add-on bootstrapping for the cluster resource.

The module also creates the Auto Mode cluster IAM policies and the Auto Mode node IAM role. AWS requires the node role to be separate from the cluster role.

References:

- [AWS EKS Auto Mode cluster IAM role](https://docs.aws.amazon.com/eks/latest/userguide/auto-cluster-iam-role.html)
- [AWS EKS Auto Mode node IAM role](https://docs.aws.amazon.com/eks/latest/userguide/auto-create-node-role.html)
- [AWS built-in Auto Mode node pools](https://docs.aws.amazon.com/eks/latest/userguide/set-builtin-node-pools.html)
- [AWS EKS Auto Mode ALB IngressClassParams](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-alb.html)
- [Terraform AWS provider EKS Auto Mode arguments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
- [terraform-aws-modules/eks Auto Mode example](https://github.com/terraform-aws-modules/terraform-aws-eks#eks-auto-mode)

## Private Ingress

The intended ingress path is:

```text
Client -> API Gateway HTTP API -> VPC Link -> internal ALB -> EKS service
```

There are no public subnets and no internet gateway in this VPC, so internet-facing Kubernetes load balancers cannot be provisioned. Private subnets remain tagged for internal load balancers.

Ingress is split into platform-owned and app-owned manifests:

- Platform: [examples/kubernetes/platform/ingress-class-internal.yaml](./examples/kubernetes/platform/ingress-class-internal.yaml) — `IngressClass` + `IngressClassParams` (scheme, subnets, group, ALB attrs). Apply once per cluster, or manage via Argo CD.
- App: [examples/kubernetes/app/sample-ingress.yaml](./examples/kubernetes/app/sample-ingress.yaml) — copy per workload, set `ingressClassName: internal-alb` and your rules.

All Ingresses on the `internal-alb` class merge onto a single shared internal ALB (configured via `spec.group.name` on the IngressClassParams).

After the internal ALB listener exists, enable the HTTP API private integration:

```hcl
enable_http_api_gateway        = true
internal_alb_listener_arn      = "arn:aws:elasticloadbalancing:REGION:ACCOUNT_ID:listener/app/..."
internal_alb_security_group_id = "sg-..."
internal_alb_listener_port     = 443

http_api_authorization_type = "AWS_IAM"
http_api_private_integration_tls_server_name = "internal.example.gov"
```

For public user-facing APIs, configure `http_api_jwt_authorizer` instead of `AWS_IAM`. More detail is in [docs/private-ingress.md](./docs/private-ingress.md).

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
- `enable_http_api_gateway`
- `internal_alb_listener_arn`
- `internal_alb_security_group_id`
- `http_api_authorization_type` or `http_api_jwt_authorizer`
- `tags`

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
