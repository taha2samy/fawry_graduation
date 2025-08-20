locals {
  subnets = {
    "private-a" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block,6,0)
      az_index   = 0
      is_public  = false
    },
    "private-b" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block,6,1)
      az_index   = 1
      is_public  = false
    },
    "public-bastion-c" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block,6,2)
      az_index   = 2
      is_public  = true
    }
  }
}