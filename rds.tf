# Doc: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide
# RDS Configuration
resource "aws_db_instance" "rds" {
  identifier             = var.rds_name
  allocated_storage      = 20
  db_name                = var.rds_name
  engine                 = "mysql"
  engine_version         = "8.0.36"
  instance_class         = "db.t4g.micro"
  username               = var.username
  password               = var.password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  multi_az               = false
  # To allow public access from the internet
  publicly_accessible  = true
  parameter_group_name = aws_db_parameter_group.default.name
}

# Parameter group
resource "aws_db_parameter_group" "default" {
  name   = "mysql-custom"
  family = "mysql8.0"

  # To avoid "unable to resolve IP" error
  parameter {
    name  = "skip_name_resolve"
    value = "1"
    # To avoid  Error "cannot use immediate apply method for static parameter"
    apply_method = "pending-reboot"
  }
}


# RDS Subnet Group
## There should be minimum of two subnets in a subnet group
resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.rds_name}-subnet-group"
  subnet_ids = [aws_subnet.rds-priamry-instance.id, aws_subnet.rds-secondary-instance.id]

  tags = {
    Name = "${var.rds_name}-subnet-group"
  }
}
