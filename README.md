# Enterprise AWS EKS Auto Mode Terraform

This repository provisions an AWS foundation for an enterprise web application across separate `dev`, `test`, and `prod` environments.

It creates:

- A dedicated VPC per environment across 3 Availability Zones.
- Public subnets for internet-facing load balancers.
- Private subnets for EKS Auto Mode nodes.
- NAT egress for private subnets, with one NAT gateway in non-prod and one per AZ in prod.
- Amazon EKS with Auto Mode compute enabled.
- Built-in EKS Auto Mode `system` and `general-purpose` node pools.
- EKS API authentication through access entries, not `aws-auth`.
- KMS-backed Kubernetes secret encryption.
- EKS control plane logs.
- VPC flow logs.
- IRSA OIDC provider for workloads that still use IAM roles for service accounts.

## Repository Layout

```text
.
├── environments/
│   ├── dev/
│   ├── test/
│   └── prod/
├── modules/
│   └── eks-auto-mode-platform/
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
- [Terraform AWS provider EKS Auto Mode arguments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
- [terraform-aws-modules/eks Auto Mode example](https://github.com/terraform-aws-modules/terraform-aws-eks#eks-auto-mode)

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
- `endpoint_public_access` and `endpoint_public_access_cidrs`
- `tags`

By default, the EKS API endpoint is private only. If you need a public endpoint, set `endpoint_public_access = true` and restrict `endpoint_public_access_cidrs` to corporate/VPN CIDRs.

For production, `single_nat_gateway = false` creates one NAT gateway per AZ and `deletion_protection = true` protects the EKS cluster.

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

Use Kubernetes service annotations or Gateway/Ingress resources to request AWS load balancers. Public and private subnets are tagged for AWS load balancer discovery.

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
