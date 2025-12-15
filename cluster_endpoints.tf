resource "aws_security_group" "vpce" {
  count  = var.vpce_enabled ? 1 : 0
  name   = "${var.environment_name}-vpce"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "HTTPS from within VPC (pods/nodes)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.environment_name}-vpce"
  })
}

resource "aws_vpc_endpoint" "s3" {
  count = var.vpce_enabled ? 1 : 0

  vpc_id            = aws_vpc.vpc.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = aws_route_table.private[*].id

  tags = merge(local.tags, {
    Name = "${var.environment_name}-vpce-s3"
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.vpce_enabled ? toset(local.vpce_interface_services) : toset([])

  vpc_id              = aws_vpc.vpc.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce[0].id]

  tags = merge(local.tags, {
    Name = "${var.environment_name}-vpce-${each.value}"
  })
}
