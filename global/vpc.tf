resource "aws_vpc" "main" {
  cidr_block                       = var.vpc_cidr_block
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_egress_only_internet_gateway" "egw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "main" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = data.aws_availability_zones.available.names[each.value.az_index]
  map_public_ip_on_launch = each.value.is_public

  tags = {
    Name = "subnet-${each.key}"
    "kubernetes.io/cluster/api.${var.kops_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = each.value.is_public ? "1" : null
    "kubernetes.io/role/internal-elb"             = !each.value.is_public ? "1" : null
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  for_each = { for k, v in local.subnets : k => v if !v.is_public }
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egw.id
  }
}


resource "aws_route_table_association" "public" {
  for_each = { for k, v in local.subnets : k => v if v.is_public }

  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = { for k, v in local.subnets : k => v if !v.is_public }

  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}