module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_network_address_usage_metrics = true
  map_public_ip_on_launch              = false

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  private_subnet_tags = merge(
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"             = "1"
    },
    var.private_subnet_tags,
  )

  public_subnet_tags = merge(
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    },
    var.enable_public_load_balancer_subnet_tags ? { "kubernetes.io/role/elb" = "1" } : {},
    var.public_subnet_tags,
  )

  tags = local.common_tags
}
