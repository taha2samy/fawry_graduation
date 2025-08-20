data "aws_ami" "fck_nat" {
  most_recent = true
  owners      = ["568608671756"]


}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "main" {
  key_name   = "main-access-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.root}/../private.pem"  
  file_permission = "0400"
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = "${path.root}/../public.pub"    
  file_permission = "0400"
}


resource "aws_security_group" "nat" {
  name        = "nat-instance-sg"
  description = "For NAT instance with Bastion access"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "nat-sg" }
}

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.fck_nat.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main["public-bastion-c"].id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.nat.id]
  source_dest_check           = false

  tags = {
    Name = "NAT Instance (fck-nat)"
  }
}