# VPC and Networking Resources
resource "aws_vpc" "main" {
  count = var.existing_vpc_id == null ? 1 : 0
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

locals {
  vpc_id          = var.existing_vpc_id != null ? var.existing_vpc_id : aws_vpc.main[0].id
  public_subnets  = length(var.existing_public_subnet_ids) > 0 ? var.existing_public_subnet_ids : aws_subnet.public[*].id
  private_subnets = length(var.existing_private_subnet_ids) > 0 ? var.existing_private_subnet_ids : aws_subnet.private[*].id
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.existing_public_subnet_ids) == 0 ? 2 : 0
  
  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.existing_private_subnet_ids) == 0 ? 2 : 0
  
  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

# Internet Gateway (only if creating VPC)
resource "aws_internet_gateway" "main" {
  count = var.existing_vpc_id == null ? 1 : 0
  
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# NAT Gateway (only if creating VPC)
resource "aws_eip" "nat" {
  count = var.existing_vpc_id == null ? 1 : 0
  
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count = var.existing_vpc_id == null && length(aws_subnet.public) > 0 ? 1 : 0
  
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  count = var.existing_vpc_id == null ? 1 : 0
  
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count = var.existing_vpc_id == null ? 1 : 0
  
  vpc_id = local.vpc_id

  dynamic "route" {
    for_each = length(aws_nat_gateway.main) > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.existing_vpc_id == null && length(aws_subnet.public) > 0 ? 2 : 0
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = var.existing_vpc_id == null && length(aws_subnet.private) > 0 ? 2 : 0
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-ecs-"
  vpc_id      = local.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}
