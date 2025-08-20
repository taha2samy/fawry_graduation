
resource "aws_route53_zone" "k8s_private" {
  name = "internal.${var.kops_cluster_name}"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  force_destroy = true
  tags = {
    Name = "Private Zone for Kubernetes"
  }
}