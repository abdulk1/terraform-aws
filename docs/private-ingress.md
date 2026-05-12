# Private Ingress With HTTP API Gateway

The intended ingress path is:

```text
Client -> API Gateway HTTP API -> VPC Link -> internal ALB -> EKS service
```

The Kubernetes ALB must be internal. Public subnet discovery for internet-facing Kubernetes load balancers is disabled by default by setting:

```hcl
enable_public_load_balancer_subnet_tags = false
```

Private subnets remain tagged with `kubernetes.io/role/internal-elb = 1`.

## Create The Internal ALB

Apply the EKS Auto Mode ingress example after the service exists:

```sh
kubectl apply -f examples/kubernetes/internal-alb-ingress.yaml
kubectl get ingress webapp -n default
```

The ALB DNS name should start with `internal-`.

## Enable HTTP API Gateway

After the internal ALB listener and security group exist, set these values in the target environment:

```hcl
enable_http_api_gateway        = true
internal_alb_listener_arn      = "arn:aws:elasticloadbalancing:REGION:ACCOUNT_ID:listener/app/..."
internal_alb_security_group_id = "sg-..."
internal_alb_listener_port     = 443

http_api_authorization_type = "AWS_IAM"
http_api_private_integration_tls_server_name = "internal.example.gov"
```

For public user-facing applications, configure `http_api_jwt_authorizer` instead of `AWS_IAM`.

## Operational Notes

- The HTTP API endpoint is public unless you disable the execute-api endpoint and attach a custom domain.
- API Gateway private integration resources must be in the same AWS account as the load balancer and VPC Link.
- Use HTTPS on the private ALB listener for FISMA workloads.
- If Terraform manages `manage_internal_alb_security_group_rule`, it adds the ALB ingress rule from the API Gateway VPC Link security group.
