resource "aws_vpc" "private_vpc" {
    cidr_block = "10.46.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
}

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
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
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


resource "aws_instance" "just_for_ssh" {
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_public.id
  ami           = data.aws_ami.get_ami.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.ssh_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    # Enable TCP forwarding in sshd_config
    if grep -q "^AllowTcpForwarding" /etc/ssh/sshd_config; then
      sed -i 's/^AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
    else
      echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
    fi

    # Optional: Allow binding to non-localhost
    if ! grep -q "^GatewayPorts" /etc/ssh/sshd_config; then
      echo "GatewayPorts yes" >> /etc/ssh/sshd_config
    fi

    # Restart SSH service
    systemctl restart sshd
  EOF
  user_data_replace_on_change = true
  tags = {
    Name = "Bastion Host (Jumping Box)"
  }
}
