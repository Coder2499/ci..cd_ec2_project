variable "environment" {
  description = "Environment name"
  type        = string
}

variable "base_name" {
  description = "Base name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}