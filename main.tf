module "ec2" {
  source = "./modules/ec2"

  instance_type = var.instance_type
  base_name     = var.base_name
  environment   = var.environment
}