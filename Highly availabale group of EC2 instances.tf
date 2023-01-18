terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.49.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  # access_key = "my-access-key"
  # secret_key = "my-secret-key"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "my-app-vpc"
  }
}