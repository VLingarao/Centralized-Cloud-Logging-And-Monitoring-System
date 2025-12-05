variable "aws_region" {
  default = "ap-south-2"
}

variable "vpc_id" {
  description = "Vpc Id"
  type = string
  default = "vpc-id"
}
variable "subnet_id" {
  description = "Subnet ID"
  type = string
  default = "subnet-id"
}
variable "ami_id" {
  description = "Ami Id"
  type = string
  default = "ami-0a9098891d675c629"
}
variable "instance_type" {
  description = "Instance Type"
  type = string
  default = "t3.micro"
}

variable "user_email" {
  description = "User Email"
  type = string
  default = "addyourmail@gmail.com"
}