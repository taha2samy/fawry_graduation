resource "aws_vpc" "private_vpc" {
    cidr_block = "10.46.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    assign_generated_ipv6_cidr_block = true
    
    
}
resource "aws_security_group" "ssh" {
  name        = "ssh-sg"
  description = "Allow SSH inbound, all outbound"
  vpc_id      = aws_vpc.private_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "Allow DNS queries (UDP) from within the VPC"
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [aws_vpc.private_vpc.cidr_block]
  }
  ingress {
    description = "Allow DNS queries (TCP) from within the VPC"
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [aws_vpc.private_vpc.cidr_block]
  }



}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.private_vpc.id
}

resource "aws_egress_only_internet_gateway" "egw" {
  vpc_id = aws_vpc.private_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.private_vpc.id
  # route {
  #   ipv6_cidr_block = "::/0"
  #   gateway_id      = aws_internet_gateway.igw.id
  # }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.private_vpc.id
  route {
    ipv6_cidr_block        = "::/0" 
    egress_only_gateway_id = aws_egress_only_internet_gateway.egw.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_instance.fck_nat_with_ssh.primary_network_interface_id

  }

}

resource "aws_subnet" "k8s" {
  for_each = local.subnets_k8s

  vpc_id                          = aws_vpc.private_vpc.id
  cidr_block                      = each.value.cidr
  map_public_ip_on_launch         = each.value.public
  availability_zone               = each.value.availability_zone
  assign_ipv6_address_on_creation = true
  ipv6_cidr_block = cidrsubnet(
    aws_vpc.private_vpc.ipv6_cidr_block,
    8,
    index(keys(local.subnets_k8s), each.key)
  )

  tags = {
    Name = "Subnet-${each.key}"
    "kubernetes.io/cluster/${var.kops_cluster_name}" = "shared"
    "kubernetes.io/role/elb" = each.value.public ? "1" : null
    "kubernetes.io/role/internal-elb" = !each.value.public ? "1" : null
  }
}

resource "aws_subnet" "bastion" {
  vpc_id                          = aws_vpc.private_vpc.id
  cidr_block                      = local.subnets["bastion-public-subnet"].cidr
  map_public_ip_on_launch         = local.subnets["bastion-public-subnet"].public
  availability_zone               = local.subnets["bastion-public-subnet"].availability_zone
  assign_ipv6_address_on_creation = true
  ipv6_cidr_block = cidrsubnet(aws_vpc.private_vpc.ipv6_cidr_block,8,length(local.subnets_k8s))
  
  tags = {
    Name    = "Subnet-bastion-public-subnet"
    Purpose = "Bastion-Host-Access"
  }
}
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.k8s
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.bastion.id
  route_table_id = aws_route_table.public_rt.id
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

resource "aws_security_group" "fck_nat_sg_with_ssh" {
  name        = "fck-nat-sg"
  description = "Allows traffic for fck-nat instance"
  vpc_id      = aws_vpc.private_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = [aws_vpc.private_vpc.cidr_block] 
    ipv6_cidr_blocks = [aws_vpc.private_vpc.ipv6_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

  }

  tags = {
    Name = "fck-nat-sg"
  }
}

