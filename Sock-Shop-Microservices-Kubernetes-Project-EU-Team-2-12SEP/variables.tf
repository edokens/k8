variable "region" {
  default     = "us-west-2"
  description = "the region to be created"
}

variable "ami" {
  default     = "ami-0d70546e43a941d70"
  description = "the ubuntu ami for our instances"
}

variable "instance_type" {
  default     = "t3.medium"
  description = "we require 2CPU for our instance type"
}

variable "az1" {
  default     = "us-west-2a"
  description = "the zone to be created"
}

variable "az2" {
  default     = "us-west-2b"
  description = "the zone to be created"
}

variable "pub1_cidr" {
  default     = "10.0.1.0/24"
  description = "the first public subnet cidr"
}

variable "pub2_cidr" {
  default     = "10.0.2.0/24"
  description = "the second public subnet cidr"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "the vpc cidr"
}

variable "all_cidr" {
  default     = "0.0.0.0/0"
  description = "the route cidr"
}

# variable "key_name" {
#   default = "sock_key" 
# }
# variable "sock_key" {
#   default     = "~/keypairs/sock_key.pub"
#   description = "path to my keypairs"
# }

variable "kubenetes-key" {
  default     = "~/keypairs/kubenetes-key.pub"
  description = "path to my keypairs"
}
variable "keyname" {
  default = "kubenetes-key"
}