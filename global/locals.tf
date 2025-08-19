locals {
  subnets_k8s = {
    "k8s-private-subnet-1" = {
      cidr              = "10.46.0.0/18"
      public            = false
      availability_zone = data.aws_availability_zones.region.names[0]
    }
    "k8s-private-subnet-2" = {
      cidr              = "10.46.64.0/18"
      public            = false
      availability_zone = data.aws_availability_zones.region.names[1]
    }
  }

  subnets = {
    "bastion-public-subnet" = {
      cidr              = "10.46.128.0/18"
      public            = true
      availability_zone = data.aws_availability_zones.region.names[2]
    }
  }
}