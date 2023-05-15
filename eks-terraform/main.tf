terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key            = "eks-terraform.tfstate"
    encrypt        = true
    dynamodb_table = "s3-backend-state"
    bucket         = "example-s3-backend-bucket"
    region         = "ap-southeast-2"
  }
}
