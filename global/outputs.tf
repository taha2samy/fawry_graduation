output "private_zone_id" {
  description = "The ID of the private Route53 zone."
  value       = aws_route53_zone.k8s_private.id
}

output "vpc_id" {
  description = "The ID of the main VPC."
  value       = aws_vpc.main.id
}

output "k8s_subnets" {
  description = "Map of the created Kubernetes subnets."
  value       = { for k, v in aws_subnet.main : k => v if !v.map_public_ip_on_launch }
}

output "s3_url" {
  description = "The S3 URL for the backend bucket."
  value       = "s3://${aws_s3_bucket.backend.bucket}"
}

output "public_dns" {
  description = "Public DNS of the NAT instance."
  value       = aws_instance.nat.public_dns
}

output "private_key_file" {
  description = "Path to the private key file for SSH access."
  value       = local_file.private_key.filename
}