provider "aws" {
    region = "eu-west-1"
    alias = "just_region"
}
data "aws_availability_zones" "region" {
  provider = aws.just_region
  state    = "available"
}

