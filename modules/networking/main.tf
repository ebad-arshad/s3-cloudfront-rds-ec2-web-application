# ================================ VPC ================================ #

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Backend-VPC-${terraform.workspace}"
  }
}

# ================================ Subnet ================================ #

data "aws_availability_zones" "available" {}

resource "aws_subnet" "backend_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Backend-Subnet-${terraform.workspace}"
  }
}

resource "aws_subnet" "rds_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "RDS-Subnet-${terraform.workspace}"
  }
}


resource "aws_subnet" "rds_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "RDS-Subnet-${terraform.workspace}"
  }
}

# ================================ RDS Subnet Group ================================ #

resource "aws_db_subnet_group" "rds_group" {
  name       = "main-rds-group-${terraform.workspace}"
  subnet_ids = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]

  tags = {
    Name = "RDS-Subnet-Group-${terraform.workspace}"
  }
}

# ================================ Internet Gateway ================================ #

resource "aws_internet_gateway" "backend_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Backend-Internet-Gateway-${terraform.workspace}"
  }
}

# ================================ Route Table ================================ #

resource "aws_route_table" "backend_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.backend_igw.id
  }

  tags = {
    Name = "Backend-Route-Table-${terraform.workspace}"
  }
}

resource "aws_route_table" "rds_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "RDS-Route-Table-${terraform.workspace}"
  }
}

# ================================ Route Table Association ================================ #

resource "aws_route_table_association" "backend_rta" {
  subnet_id      = aws_subnet.backend_subnet.id
  route_table_id = aws_route_table.backend_rt.id
}

resource "aws_route_table_association" "rds_1_rta" {
  subnet_id      = aws_subnet.rds_subnet_1.id
  route_table_id = aws_route_table.rds_rt.id
}

resource "aws_route_table_association" "rds_2_rta" {
  subnet_id      = aws_subnet.rds_subnet_2.id
  route_table_id = aws_route_table.rds_rt.id
}

# ================================ Security Group ================================ #

resource "aws_security_group" "backend_sg" {
  name   = "backend-sg-${terraform.workspace}"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Backend-SG-${terraform.workspace}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_backend_http" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_backend_ssh" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = var.user_ip
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg-${terraform.workspace}"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "RDS-SG-${terraform.workspace}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_rds_mysql" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.backend_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}