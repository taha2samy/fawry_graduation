output "private_zone_id" {
  value = aws_route53_zone.k8s_private.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "k8s_subnets" {
  value = { for k, v in aws_subnet.main : k => v if !v.map_public_ip_on_launch }
}

output "k8s_utility_subnets" {
  value = { for k, v in aws_subnet.main : k => v if v.map_public_ip_on_launch }
}

output "s3_url" {
  value = "s3://${aws_s3_bucket.backend.bucket}"
}

output "public_dns" {
  value = aws_instance.nat.public_dns
}

output "private_key_file" {
  value = local_file.private_key.filename
}