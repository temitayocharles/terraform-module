locals {
  enabled = var.vpc_config.enabled
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  count                = var.vpc_config.enabled ? 1 : 0
  cidr_block           = var.vpc_config.cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_config.project_config.name
  }
}

resource "aws_internet_gateway" "this" {
  count  = var.vpc_config.enabled ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  tags   = { Name = "${var.vpc_config.project_config.name}-igw" }
}

resource "aws_subnet" "public" {
  count                   = var.vpc_config.enabled ? 2 : 0
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = cidrsubnet(var.vpc_config.cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.vpc_config.project_config.name}-public-${count.index}" }
}

resource "aws_route_table" "public" {
  count  = var.vpc_config.enabled ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }
  tags = { Name = "${var.vpc_config.project_config.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = var.vpc_config.enabled ? length(aws_subnet.public) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}
