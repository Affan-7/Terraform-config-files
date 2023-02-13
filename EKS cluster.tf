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