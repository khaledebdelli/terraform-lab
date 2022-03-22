variable "env_prefix_name" {
  type        = string
  description = "please enter the environment name for example development, nodejsapp etc this will be use as prefix for example demo.example.com etc"
  default     = "development"

}
variable "access_key" {
  type = string
}
variable "secret_key" {
  type = string
}
variable "account_id" {
  type = string
}
variable "region" {
  default     = "eu-west-1"
  type        = string
  description = "Region for VPC."
}
variable "availability_zone" {
  description = "AWS availability zone e.g. eu-west-1a"
  type        = string
}
variable "subnet_prefix" {
  description = "cidr block for the subnet"
  default     = "10.0.1.0/24"
  type        = string
}
variable "private_ip" {
  description = "network interface private IP list"
  default     = "10.0.1.1"
  type        = string
}
variable "resource_prefix" {
  description = "Prefix to be used in the naming of some of the created AWS resources e.g. dg-backend"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH Key Name to be used to connect to the server"
  type        = string
}
variable "instance_type" {
  type = string
}

variable "aim" {
  type = string
  default = "ami-08ca3fed11864d6bb"
}