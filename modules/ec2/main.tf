resource "aws_instance" "this" {
  ami           = "ami-045443a70fafb8bbc" # change region-wise
  instance_type = var.instance_type

  tags = {
    Name = "${var.base_name}-${var.environment}"
  }
}