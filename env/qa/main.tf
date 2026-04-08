terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket9991"
    key            = "qa/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile   = true
  }
}

provider "aws" {
  region = "ap-south-1"
}

module "ec2" {
  source = "../../modules/ec2"

  base_name     = var.base_name
  environment   = var.environment
  instance_type = var.instance_type
}