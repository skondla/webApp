variable "name" {
  default = "myservice"
}

variable "environment" {
  default = "production"
}

##################
#  Networking
##################
variable "cidr" {
  default = "33.0.0.0/16"
}
variable "availability_zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable internal_subnets {
  default = ["33.0.32.0/19", "33.0.96.0/19", "33.0.160.0/19"]
}

variable external_subnets {
  default = ["33.0.0.0/19", "33.0.64.0/19", "33.0.128.0/19"]
}

variable private_dns_name {
  default = "sd.myservice.local"
 }
