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
  bucket                  = aws_s3_bucket.backend.id
  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
}
resource "local_file" "config" {
  filename = "${path.module}/../pre_setup/add_loadBalancer_and_certManager.sh"
  content  = templatefile("${path.module}/scripts/config.sh.tpl", {
    bucket_name = "s3://${aws_s3_bucket.backend.bucket}"
    cluster_name = var.kops_cluster_name
    state_store = var.kops_state_store
  })
}
