# Input variables

- **aws_key_name:** SSH Key pair for VPN instance
- **vpc_id:** The VPC id
- **public_subnet_id:** One of the public subnets to create the instance
- **instance_type:** Instance type of the VPN box (t2.small is mostly enough)
- **whitelist:** List of office IP addresses that you can SSH and non-VPN connected users can reach temporary profile download pages
- **whitelist_http:** List of IP addresses that you can allow HTTP connections for Let's Encrypt
- **internal_cidrs:** List of CIDRs that will be whitelisted to access the VPN server internally.
- **resource_name_prefix:** All the resources will be prefixed with the value of this variable
- **volume_size:** instance volume size

# Outputs

- **pritunl_private_ip:** Private IP address of the instance
- **pritunl_public_ip:** EIP of the VPN box

# Usage

```
provider "aws" {
  region  = "eu-west-2"
}

module "pritunl" {
  source = "github.com/poush/terraform-aws-pritunl?ref=1.0.0"

  aws_key_name         = "aws_key_name"
  vpc_id               = "${module.vpc.vpc_id}"
  public_subnet_id     = "${module.vpc.public_subnets[1]}"
  instance_type        = "t2.micro"
  resource_name_prefix = "my-pritunl"

  whitelist = [
    "<Your IP>/32",
  ]
}
```

**Please Note that it can take few minutes (ideally 3-5 minutes) for provisioner to complete after terraform completes its process. Once completed, you should see Pritunl app on the public IP of instance**
