module "compute" {
  source            = "./modules/compute"
  backend_subnet_id = module.networking.backend_subnet_id
  rds_address       = module.database.rds_address
  backend_sg_id     = module.networking.backend_sg_id
  frontend_bucket   = module.frontend.frontend_bucket
  db_user           = var.db_user
  db_password       = var.db_password
  db_database       = var.db_database
}

module "database" {
  source         = "./modules/database"
  rds_group_name = module.networking.rds_group_name
  rds_sg_id      = module.networking.rds_sg_id
  db_password    = var.db_password
  db_user        = var.db_user
}

module "frontend" {
  source             = "./modules/frontend"
  backend_public_dns = module.compute.backend_public_dns
}

module "networking" {
  source  = "./modules/networking"
  user_ip = var.user_ip
}
