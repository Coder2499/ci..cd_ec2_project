resource "aws_instance" "this" {
  ami           = "ami-0c55b159cbfafe1f0" # change region-wise
  instance_type = var.instance_type

  tags = {
    Name = "${var.base_name}-${var.environment}"
  }
}