locals {
  subnets = {
    "private-a" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block, 4, 0)
      is_public  = false
      az_index   = 0 
    },
    "private-b" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block, 4, 1)
      is_public  = false
      az_index   = 1 
    },
    "private-c" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block, 4, 2)
      is_public  = false
      az_index   = 2 
    },

    "public-a" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block, 4, 3)
      is_public  = true
      az_index   = 0  
    },
    "public-b" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block, 4, 4)
      is_public  = true
      az_index   = 1  
    },
    "public-c" = {
      cidr_block = cidrsubnet(var.vpc_cidr_block, 4, 5)
      is_public  = true
      az_index   = 2 
    }
  }
}