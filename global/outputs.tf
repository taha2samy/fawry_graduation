output "private_zone_id" {
  value = aws_route53_zone.k8s_private.id
}
output "vpc_id" {
    value = "${aws_vpc.private_vpc.id}"
}
output "k8s_subnets" {
    value = aws_subnet.subnets
  
}
output "s3_url" {
  value = "s3://${aws_s3_bucket.backend.bucket}"
}
output "public_dns" {
  value = aws_instance.just_for_ssh.public_dns

  
}
output "private_key_file" {
  value = "${local_file.put_private.filename}"

  
}