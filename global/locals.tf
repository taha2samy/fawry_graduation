locals {
  subnets_k8s = {
    "subnets1" = {
      cidr              = "10.46.0.0/18"
      public            = true
      availability_zone = data.aws_availability_zones.region.names[0]
    }
    "subnets2" = {
      cidr              = "10.46.64.0/18"
      public            = true
      availability_zone = data.aws_availability_zones.region.names[1]
    }
   
  }

  subnets =   {"subnets3" = {
      cidr              = "10.46.128.0/18"
      public            = true
      availability_zone = data.aws_availability_zones.region.names[2]}
    }
}