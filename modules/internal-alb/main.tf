locals {
  alb_name        = coalesce(var.alb_name, "${var.name_prefix}-internal")
  is_https        = var.listener_protocol == "HTTPS"
  effective_certs = local.is_https ? var.additional_certificate_arns : []
}

resource "aws_security_group" "alb" {
  name                   = "${var.name_prefix}-internal-alb"
  description            = "Internal ALB exposing EKS workloads to in-VPC consumers"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-internal-alb"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
  for_each = toset(var.ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.listener_port
  to_port           = var.listener_port
  description       = "Listener ingress from ${each.value}"

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "from_sg" {
  for_each = toset(var.ingress_security_group_ids)

  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = var.listener_port
  to_port                      = var.listener_port
  description                  = "Listener ingress from security group ${each.value}"

  tags = var.tags
}

# Egress to anywhere in the VPC so the ALB can reach target IPs registered by
# the AWS Load Balancer Controller (TargetGroupBinding) across the private
# subnets. Workload security groups gate what actually accepts the traffic.
resource "aws_vpc_security_group_egress_rule" "to_vpc" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  ip_protocol       = "-1"
  description       = "ALB egress to VPC targets"

  tags = var.tags
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_lb" "this" {
  name               = local.alb_name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.deletion_protection
  drop_invalid_header_fields = var.drop_invalid_header_fields

  dynamic "access_logs" {
    for_each = var.access_logs == null ? [] : [var.access_logs]

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.listener_protocol != "HTTPS" || var.certificate_arn != null
      error_message = "certificate_arn is required when listener_protocol is HTTPS."
    }
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  ssl_policy        = local.is_https ? var.ssl_policy : null
  certificate_arn   = local.is_https ? var.certificate_arn : null

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_certificate" "additional" {
  for_each = toset(local.effective_certs)

  listener_arn    = aws_lb_listener.this.arn
  certificate_arn = each.value
}
