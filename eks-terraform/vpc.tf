module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  name            = "eks-vpc-example"
  cidr            = "10.10.0.0/16"
  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  public_subnets  = ["10.10.4.0/24", "10.0.5.0/24", "10.10.6.0/24"]
  enable_nat_gateway = true
}
