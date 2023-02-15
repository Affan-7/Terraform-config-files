terraform {
	required_providers {
		aws = {
		source = "hashicorp/aws"
		version = "4.48.0"
		}
	}
}

provider "aws" {
region = "us-east-1"
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"

	tags = {
		Name = "eks_vpc"
	}
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks_igw"
  }
}

resource "aws_subnet" "eks_private_us_east_1a" {
  vpc_id     = aws_vpc.eks_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "eks_private_us_east_1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/cluster-name" = "shared"
  }
}