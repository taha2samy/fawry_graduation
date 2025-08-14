resource "aws_subnet" "subnets" {
    for_each = local.subnets_k8s
    vpc_id = aws_vpc.private_vpc.id
    cidr_block = each.value.cidr
    map_public_ip_on_launch = each.value.public
    availability_zone = each.value.availability_zone
tags = {
    Name = "Subnet-${each.key}"
    "kubernetes.io/cluster/${var.kops_cluster_name}" = "shared"
    "kubernetes.io/role/elb" = each.value.public ? "1" : null
    "kubernetes.io/role/internal-elb" = !each.value.public ? "1" : null
  }

}
resource "aws_route53_zone" "k8s_private" {
  name = "internal.${var.kops_cluster_name}" 

  vpc {
    vpc_id = aws_vpc.private_vpc.id 
  }
  force_destroy = true

  tags = {
    Name = "Private Zone for Kubernetes"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.private_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.private_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "private" {
  for_each       = { for k, v in local.subnets_k8s : k => v if v.public }
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_subnet" "subnet_public" {
    vpc_id = aws_vpc.private_vpc.id
    cidr_block = local.subnets["subnets3"].cidr
    map_public_ip_on_launch = local.subnets["subnets3"].public
    availability_zone = local.subnets["subnets3"].availability_zone
tags = {
    Name = "Subnet-subnets3"
    "kubernetes.io/cluster/${var.kops_cluster_name}" = "shared"
    "kubernetes.io/role/elb" = local.subnets["subnets3"].public ? "1" : null
    "kubernetes.io/role/internal-elb" = local.subnets["subnets3"].public ? "1" : null
  }

}
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.public_rt.id
}
