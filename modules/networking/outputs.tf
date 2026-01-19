output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc" {
  value = aws_vpc.vpc
}

output "backend_subnet_id" {
  value = aws_subnet.backend_subnet.id
}

output "rds_group_name" {
  value = aws_db_subnet_group.rds_group.name
}

output "backend_sg_id" {
  value = aws_security_group.backend_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}