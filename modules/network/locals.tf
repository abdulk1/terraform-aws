locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, index)
  ]

  # AWS service interface endpoints required for EKS Auto Mode and typical workload
  # operation in a fully private VPC (no NAT, no IGW).
  interface_endpoint_services = [
    "ec2",
    "ec2messages",
    "ecr.api",
    "ecr.dkr",
    "eks",
    "eks-auth",
    "elasticloadbalancing",
    "autoscaling",
    "sts",
    "kms",
    "logs",
    "ssm",
    "ssmmessages",
  ]
}
