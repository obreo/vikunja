# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.1.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

# EC2 Subnet - Primary
resource "aws_subnet" "public-primary-instance" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnet_a_name}"
  }
}

# EC2 Subnet - Secondary
resource "aws_subnet" "public-secondary-instance" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnet_aa_name}"
  }
}

# RDS Subnet - Primary
resource "aws_subnet" "rds-priamry-instance" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnet_b_name}"
  }
}

# RDS Subnet - Secondary
resource "aws_subnet" "rds-secondary-instance" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.4.0/24"
  availability_zone       = "us-east-1d"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnet_c_name}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gate_w" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-gate_w"
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}


# Route table
# Routing all subnet to the internet / and later restricting access using ACLs
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gate_w.id
  }

  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_route_table_association" "public_instance-a" {
  subnet_id      = aws_subnet.public-primary-instance.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "public_instance-b" {
  subnet_id      = aws_subnet.public-secondary-instance.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "rds_a" {
  subnet_id      = aws_subnet.rds-priamry-instance.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "rds_b" {
  subnet_id      = aws_subnet.rds-secondary-instance.id
  route_table_id = aws_route_table.route-table.id
}

# Security Groups
#Instances - Allowing ports 80 & 443 & 22
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name  = "allow_tls"
    Ports = "80/443/22"
  }
}
# Inbound
resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh0" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3456
  ip_protocol       = "tcp"
  to_port           = 3456
}
# Outbound
resource "aws_vpc_security_group_egress_rule" "instacne_allow_all_egress" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# Database - Allowing port for mySQL
resource "aws_security_group" "rds" {
  name        = "RDS-MySQL"
  description = "Allow access MySQL"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name  = "allow_MySQL_access"
    Ports = "3306"
  }
}
# Ingress
resource "aws_vpc_security_group_ingress_rule" "allow_database" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}
# Outgress
resource "aws_vpc_security_group_egress_rule" "allow_database_egress" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
/*
# ACLs
# ACL to mySQL
resource "aws_network_acl" "acl_database" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.rds-priamry-instance.id]

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 3306
    to_port    = 3306
  }

  tags = {
    Name = "${var.vpc_name}"
  }
}
*/

# Security Group - Application Load Balancer
#Instances - Allowing ports 80 & 443 & 22
resource "aws_security_group" "load_balancer" {
  name        = "load_balancer_allow_tcp"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name  = "allow_tcp"
    Ports = "80/443"
  }
}
# Ingress
resource "aws_vpc_security_group_ingress_rule" "loadbalancer_allow_vikunja" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3456
  ip_protocol       = "tcp"
  to_port           = 3456
}
resource "aws_vpc_security_group_ingress_rule" "loadbalancer_allow_http" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "loadbalancer_allow_https" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Outgress
resource "aws_vpc_security_group_egress_rule" "loadbalance_allow_all_egress" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
