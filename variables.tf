variable "aws_key_name" {
  description = "SSH keypair name for the VPN instance"
	# default = "mykey"
}

variable "aws_region" {
  description = "The aws region"
}


variable "vpc_id" {
  description = "Which VPC VPN server will be created in"
}

variable "public_subnet_id" {
  description = "One of the public subnet id for the VPN instance"
}

variable "instance_type" {
  description = "Instance type for VPN Box"
  type        = string
  default     = "t2.micro"
}

variable "whitelist" {
  description = "[List] Office IP CIDRs for SSH and HTTPS"
  type        = list(string)
}

variable "whitelist_http" {
  description = "[List] Whitelist for HTTP port to validate Let's Encrypt SSL"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "resource_name_prefix" {
  description = "All the resources will be prefixed with the value of this variable"
  default     = "pritunl"
}

variable "internal_cidrs" {
  description = "[List] IP CIDRs to whitelist in the pritunl's security group"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "volume_size" {
  description = "ec2 volume size"
  default = 20
}


