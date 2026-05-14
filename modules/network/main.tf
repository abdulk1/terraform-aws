module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnet_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  # FISMA baseline: no NAT gateway, no internet gateway, no public subnets.
  # Egress to AWS services flows over the VPC endpoints in endpoints.tf.
  enable_nat_gateway = false
  create_igw         = false

  enable_network_address_usage_metrics = true
  map_public_ip_on_launch              = false

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  private_subnet_tags = merge(
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    },
    var.private_subnet_tags,
  )

  tags = var.tags
}
