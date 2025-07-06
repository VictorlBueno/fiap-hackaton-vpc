locals {
  vpc_cidr = var.vpc_cidr
  azs      = var.availability_zones
  
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.tags, {
    Name = "fiap-hack-vpc"
  })
}

resource "aws_subnet" "public" {
  count             = length(local.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_subnets[count.index]
  availability_zone = local.azs[count.index]
  
  map_public_ip_on_launch = true
  
  tags = merge(local.tags, {
    Name = "fiap-hack-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  count             = length(local.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]
  
  tags = merge(local.tags, {
    Name = "fiap-hack-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.tags, {
    Name = "fiap-hack-igw"
  })
}

resource "aws_eip" "nat" {
  count = length(local.private_subnets)
  domain = "vpc"
  
  tags = merge(local.tags, {
    Name = "fiap-hack-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count         = length(local.private_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(local.tags, {
    Name = "fiap-hack-nat-gateway-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(local.tags, {
    Name = "fiap-hack-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = length(local.private_subnets)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = merge(local.tags, {
    Name = "fiap-hack-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(local.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "eks_cluster" {
  name_prefix = "fiap-hack-eks-cluster-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.tags, {
    Name = "fiap-hack-eks-cluster-sg"
  })
}

resource "aws_security_group" "eks_nodes" {
  name_prefix = "fiap-hack-eks-nodes-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  ingress {
    from_port = 1025
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.tags, {
    Name = "fiap-hack-eks-nodes-sg"
  })
}

output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "cluster_security_group_id" {
  description = "ID do security group do cluster EKS"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "ID do security group dos nodes EKS"
  value       = aws_security_group.eks_nodes.id
} 