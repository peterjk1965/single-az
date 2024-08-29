variable "az-1" {
  type    = string
  default = "us-east-2a"
}

variable "ec2-ami" {
  type    = string
  default = "ami-0a4387db64822e3c1"
}

variable "all-ipv4" {
  type    = string
  default = "0.0.0.0/0"
}

variable "default-instance" {
  type    = string
  default = "t2.micro"
}

variable "my-ipv4" {
  type    = string
  default = "69.136.168.38/32"
}

variable "key-name" {
  type    = string
  default = "ohio"
}

