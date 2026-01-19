provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
    }
  }
}