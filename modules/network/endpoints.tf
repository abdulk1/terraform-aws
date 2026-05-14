resource "aws_security_group" "vpc_endpoints" {
  name                   = "${var.name_prefix}-vpce"
  description            = "HTTPS ingress from the VPC to AWS service interface endpoints"
  vpc_id                 = module.vpc.vpc_id
  revoke_rules_on_delete = true

  ingress {
    description = "HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpce"
    }
  )
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpce-s3"
    }
  )
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoint_services)

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpce-${each.value}"
    }
  )
}
