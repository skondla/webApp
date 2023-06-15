####################
# VPC
####################
resource "aws_vpc" "main" {
  cidr_block                       = var.cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Terraform   = true
  }
}

####################
# Service discovery
####################
resource "aws_service_discovery_private_dns_namespace" "private" {
  name        = var.private_dns_name
  description = "Service discovery under private DNS"
  vpc         = aws_vpc.main.id
}

####################
# External subnets
####################
resource "aws_subnet" "external" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${element(var.external_subnets, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  count                   = "${length(var.external_subnets)}"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.name}-${format("external-%03d", count.index + 1)}"
    Environment = var.environment
    Terraform   = true
  }
}

####################
# Internal subnets
####################
resource "aws_subnet" "internal" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "${element(var.internal_subnets, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  count             = "${length(var.internal_subnets)}"

  tags = {
    Name        = "${var.name}-${format("internal-%03d", count.index + 1)}"
    Environment = var.environment
    Terraform   = true
  }
}


####################
# NAT EIP
####################
resource "aws_eip" "nat" {
  vpc = true
}

####################
# Default security group
####################
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr]
    description = "VPC CIDR"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

####################
# IGW
####################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Terraform   = true
  }
}

####################
# NAT gateway
####################
resource "aws_nat_gateway" "main" {
  count         = 1
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.external.*.id, count.index)}"
  depends_on    = ["aws_internet_gateway.main"]

  tags = {
    Name      = "${var.environment} NAT"
    Terraform = true
  }
}

####################
# VPC IGW route table
####################
resource "aws_route_table" "vpc_igw" {
  vpc_id     = aws_vpc.main.id
  depends_on = ["aws_internet_gateway.main"]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Environment = var.environment
    Terraform   = true
  }
}

resource "aws_route_table_association" "external_subnet_a" {
  depends_on     = ["aws_subnet.external"]
  subnet_id      = "${element(aws_subnet.external.*.id, 0)}"
  route_table_id = aws_route_table.vpc_igw.id
}

resource "aws_route_table_association" "external_subnet_b" {
  depends_on     = ["aws_subnet.external"]
  subnet_id      = "${element(aws_subnet.external.*.id, 1)}"
  route_table_id = aws_route_table.vpc_igw.id
}

resource "aws_route_table_association" "external_subnet_c" {
  depends_on     = ["aws_subnet.external"]
  subnet_id      = "${element(aws_subnet.external.*.id, 2)}"
  route_table_id = aws_route_table.vpc_igw.id
}
