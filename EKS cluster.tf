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

resource "aws_subnet" "eks_private_us_east_1b" {
  vpc_id     = aws_vpc.eks_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "eks_private_us_east_1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/cluster-name" = "shared"
  }
}

resource "aws_eip" "eks_nat_eip" {
  vpc      = true
  depends_on = [aws_internet_gateway.eks_igw]

  tags = {
    Name = "eks_nat_eip"
  }
}

resource "aws_nat_gateway" "eks_nat" {
  allocation_id = aws_eip.eks_nat_eip.id
  subnet_id     = aws_subnet.eks_public_us_east_1a.id

  tags = {
    Name = "eks_nat"
  }

  depends_on = [aws_internet_gateway.eks_igw]
}

resource "aws_route_table" "eks_private_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.eks_nat.id
  }

  tags = {
    Name = "eks_private_rt"
  }
}

resource "aws_route_table" "eks_public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks_public_rt"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "myapp_eks" {
  name     = "myapp_eks"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.eks_private_us_east_1a.id,
      aws_subnet.eks_private_us_east_1b.id,
      aws_subnet.eks_public_us_east_1a.id,
      aws_subnet.eks_public_us_east_1b.id,
    ]
    
    # endpoint_private_access = true
    # endpoint_public_access  = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

resource "aws_iam_role" "eks_nodegroup_role" {
  name = "eks_nodegroup_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}