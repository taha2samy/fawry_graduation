provider "aws" {
  region = eu-west-1
  alias = "just_name_region"
}

data "aws_availability_zones" "region" {
  state = "available"
}
