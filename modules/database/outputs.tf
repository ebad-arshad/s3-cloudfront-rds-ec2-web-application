output "db_password" {
  value = aws_db_instance.my_sql.password
}

output "rds_address" {
  value = aws_db_instance.my_sql.address
}

output "aws_db_instance" {
  value = aws_db_instance.my_sql
}