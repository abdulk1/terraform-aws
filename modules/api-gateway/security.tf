resource "aws_security_group" "vpc_link" {
  name                   = "${var.name_prefix}-apigw-vpc-link"
  description            = "API Gateway HTTP API VPC Link egress to the private application ALB"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  egress {
    description     = "Allow API Gateway VPC Link traffic to the private ALB listener"
    from_port       = var.internal_alb_listener_port
    to_port         = var.internal_alb_listener_port
    protocol        = "tcp"
    security_groups = [var.internal_alb_security_group_id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-apigw-vpc-link"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "internal_alb_from_vpc_link" {
  count = var.manage_internal_alb_security_group_rule ? 1 : 0

  security_group_id            = var.internal_alb_security_group_id
  referenced_security_group_id = aws_security_group.vpc_link.id
  ip_protocol                  = "tcp"
  from_port                    = var.internal_alb_listener_port
  to_port                      = var.internal_alb_listener_port
  description                  = "Allow API Gateway VPC Link traffic to the private ALB listener"

  tags = var.tags
}
