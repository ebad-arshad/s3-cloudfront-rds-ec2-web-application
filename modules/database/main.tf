resource "aws_db_instance" "my_sql" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t4g.micro"
  username               = var.db_user
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  storage_encrypted      = true
  multi_az               = false
  db_subnet_group_name   = var.rds_group_name
  storage_type           = "gp3"
  db_name                = "transactions"
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false

  tags = {
    Name = "SQL-RDS-${terraform.workspace}"
  }
}
