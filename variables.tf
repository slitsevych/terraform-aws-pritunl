variable "aws_key_name" {
  type        = string
  description = "SSH keypair name for the VPN instance"
  default     = ""
}

variable "public_domain_name" {
  type        = string
  description = "Public domain name to lookup for A record"
  default     = ""
}

variable "private_domain_name" {
  type        = string
  description = "Private domain name to lookup for A record"
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "Which VPC VPN server will be created in"
}

variable "public_subnet_id" {
  type        = string
  description = "One of the public subnet id for the VPN instance"
}

variable "instance_type" {
  description = "Instance type for VPN Box"
  type        = string
  default     = "t3a.small"
}

variable "platform" {
  description = "Platform: amd64 or arm64"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.platform)
    error_message = "Valid values for the platform variable are amd64 or arm64"
  }
}

variable "ovpn_udp_port" {
  type        = number
  description = "port for pritunl OpenVPN UDP between 10000 and 19999"
  default     = 13403
}

variable "wireguard_udp_port" {
  type        = number
  description = "port for pritunl OpenVPN UDP between 10000 and 19999"
  default     = 15403
}

variable "custom_ami_id" {
  description = "custom AMI for ARM platform: should be Oracle 8.8"
  type        = string
  default     = ""
}

variable "whitelist_ip" {
  type        = string
  description = "Whitelist of IP for initial ssh connection"
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(any)
  default     = {}
}

variable "resource_name_prefix" {
  type        = string
  description = "All the resources will be prefixed with the value of this variable"
  default     = "vpn"
}

variable "volume_size" {
  type        = number
  description = "ec2 volume size"
  default     = 30
}

variable "aws_iam_instance_profile" {
  type        = string
  description = "Name of iam_instance_profile to assign to EC2 instance"
  default     = ""
}

variable "additional_security_group" {
  type        = list(any)
  description = "Additional security (created outside of module) group(s)"
  default     = []
}