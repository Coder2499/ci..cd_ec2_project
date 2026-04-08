terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-mikey"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock-table"
  }
}
module "ec2" {
  source      = "../../modules/ec2"
  ami         = var.ami
  base_name   = var.base_name
  environment = var.environment
}
