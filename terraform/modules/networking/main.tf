locals {
  base_tags = coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag })
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy

  tags = merge(local.base_tags, { Name = var.vpc_name }, var.tags)
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.base_tags, { Name = "${var.vpc_name}-${var.public_subnet_suffix}-${var.azs[count.index]}" }, var.tags)
}

resource "aws_internet_gateway" "this" {
  count = var.create_igw ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, { Name = var.vpc_name }, var.tags)
}

resource "aws_route_table" "public" {
  count = var.create_igw ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, { Name = "${var.vpc_name}-${var.public_subnet_suffix}" }, var.tags)
}

resource "aws_route" "public_internet_gateway" {
  count = var.create_igw ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = var.public_route_destination_cidr
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = var.create_igw ? length(var.public_subnets) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = var.private_subnet_map_public_ip

  tags = merge(local.base_tags, { Name = "${var.vpc_name}-${var.private_subnet_suffix}-${var.azs[count.index]}" }, var.tags)
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  domain = var.eip_domain

  tags = merge(local.base_tags, { Name = var.single_nat_gateway ? "${var.vpc_name}-nat" : "${var.vpc_name}-nat-${var.azs[count.index]}" }, var.tags)

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.base_tags, { Name = var.single_nat_gateway ? "${var.vpc_name}-nat" : "${var.vpc_name}-nat-${var.azs[count.index]}" }, var.tags)

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway && length(var.private_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, { Name = "${var.vpc_name}-${var.private_subnet_suffix}" }, var.tags)
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway && length(var.private_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = var.private_route_destination_cidr
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = var.enable_nat_gateway ? length(var.private_subnets) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name        = "${var.vpc_name}-vpc-endpoints"
  description = var.vpc_endpoint_security_group_description
  vpc_id      = aws_vpc.this.id

  ingress {
    description = var.vpc_endpoint_sg_ingress_description
    from_port   = var.vpc_endpoint_sg_ingress_from_port
    to_port     = var.vpc_endpoint_sg_ingress_to_port
    protocol    = var.vpc_endpoint_sg_ingress_protocol
    cidr_blocks = coalesce(var.vpc_endpoint_sg_ingress_cidr_blocks, [aws_vpc.this.cidr_block])
  }

  egress {
    from_port   = var.vpc_endpoint_sg_egress_from_port
    to_port     = var.vpc_endpoint_sg_egress_to_port
    protocol    = var.vpc_endpoint_sg_egress_protocol
    cidr_blocks = var.vpc_endpoint_sg_egress_cidr_blocks
  }

  tags = merge(local.base_tags, var.tags, { Name = "${var.vpc_name}-vpc-endpoints" })
}

resource "aws_vpc_endpoint" "logs" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.public[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = var.vpc_endpoint_private_dns_enabled

  tags = merge(local.base_tags, var.tags, { Name = "${var.vpc_name}-logs-endpoint" })
}
