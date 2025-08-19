
resource "random_string" "bucket_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "aws_s3_bucket" "backend" {
  force_destroy = true
  bucket        = "my-backend-${random_string.bucket_suffix.result}"
}
resource "aws_s3_bucket_public_access_block" "private" {
    bucket = aws_s3_bucket.backend.id
  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls       = true
}

data "aws_ami" "get_ami" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}
resource "aws_key_pair" "ssh_key" {
  key_name = "ssh_key_for_access_master"
  public_key = tls_private_key.ssh_key.public_key_openssh

}
resource "local_file" "put_private" {
  filename = "${path.root}/../private.pem"
  content  = tls_private_key.ssh_key.private_key_pem
  file_permission = 0400
}
resource "local_file" "put_public" {
  filename        = "${path.root}/../public.pub"
  content         = tls_private_key.ssh_key.public_key_openssh
  file_permission = 0644
}

resource "aws_instance" "just_for_ssh" {
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.bastion.id

  ami           = data.aws_ami.get_ami.id
  vpc_security_group_ids = [aws_security_group.dns64.id,aws_security_group.ssh.id]
  key_name               = aws_key_pair.ssh_key.key_name


  user_data_replace_on_change = true
  user_data = file("${path.module}/scripts/configure-bastion-ubuntu.sh")

  tags = {
    Name = "Bastion Host (Jumping Box)"
  }
}
resource "aws_network_interface" "dns_eni" {
  subnet_id       = aws_subnet.bastion.id
  security_groups = [aws_security_group.dns64.id,aws_security_group.ssh.id]
  source_dest_check = false

  tags = {
    Name = "ENI-for-DNS-NAT64-Gateway"
  }
}

resource "aws_network_interface_attachment" "public_eni_attachment" {
  instance_id          = aws_instance.just_for_ssh.id
  network_interface_id = aws_network_interface.dns_eni.id
  device_index         = 1
  
  
}
resource "aws_vpc_dhcp_options" "custom_dns_resolver" {
  domain_name_servers = [
    aws_network_interface.dns_eni.private_ip,
    
  ]
  domain_name = "eu-west-1.compute.internal"

  tags = {
    Name = "DHCP-Options-for-NAT64-DNS"
  }
}
resource "aws_vpc_dhcp_options_association" "dns_association" {
  vpc_id          = aws_vpc.private_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.custom_dns_resolver.id
}