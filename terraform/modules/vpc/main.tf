########################################
# VPC
########################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-vpc" })
}

########################################
# Internet Gateway
########################################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.project}-${var.environment}-igw" })
}

########################################
# Public Subnets
########################################
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-public-${var.azs[count.index]}"
    Tier = "Public"
  })
}

########################################
# Private Subnets
########################################
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-private-${var.azs[count.index]}"
    Tier = "Private"
  })
}

########################################
# Elastic IPs for NAT
########################################
resource "aws_eip" "nat" {
  count      = var.single_nat ? 1 : length(var.azs)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags       = merge(var.tags, { Name = "${var.project}-${var.environment}-nat-eip-${count.index + 1}" })
}

########################################
# NAT Gateways
########################################
resource "aws_nat_gateway" "main" {
  count         = var.single_nat ? 1 : length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]
  tags          = merge(var.tags, { Name = "${var.project}-${var.environment}-nat-${count.index + 1}" })
}

########################################
# Public Route Table
########################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-rt-public" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

########################################
# Private Route Tables
########################################
resource "aws_route_table" "private" {
  count  = var.single_nat ? 1 : length(var.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[var.single_nat ? 0 : count.index].id
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-rt-private-${count.index + 1}" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat ? 0 : count.index].id
}