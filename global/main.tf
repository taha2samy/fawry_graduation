
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
  owners      = ["137603173731"] 

  filter {
    name   = "name"
    values = ["fck-nat-amzn2023-*-x86_64-ebs"]  
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

resource "aws_instance" "fck_nat_with_ssh" {
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.bastion.id
  source_dest_check = false
  ami           = data.aws_ami.get_ami.id
  vpc_security_group_ids = [aws_security_group.fck_nat_sg_with_ssh.id]
  key_name               = aws_key_pair.ssh_key.key_name
  user_data = file("${path.module}/scripts/configure-bastion-ubuntu.sh")

  tags = {
    Name = "Bastion Host (Jumping Box)"
  }
}




