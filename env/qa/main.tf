module "ec2" {
  source      = "../../modules/ec2"
  ami         = var.ami
  base_name   = var.base_name
  environment = var.environment
}
