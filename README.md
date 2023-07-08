# Input variables

- **aws_key_name:** SSH Key pair for VPN instance
- **vpc_id:** The VPC id
- **public_subnet_id:** One of the public subnets to create the instance
- **instance_type:** Instance type of the VPN box (`t3a.small` for `amd64` or `t4g.small` for `arm64` are enough)
- **internal_cidrs:** List of CIDRs that will be whitelisted to access the VPN server internally.
- **resource_name_prefix:** All the resources will be prefixed with the value of this variable
- **volume_size:** Instance EBS volume size (default is 30GB)
- **domain_name:** Domain name to lookup for A record
- **subdomain_prefix:** Prefix for route 53 subdomain (default is `vpn`)
- **ovpn_udp_port:** Port for pritunl OpenVPN UDP connections (default is `13403`)
- **ovpn_udp_port:** Port for pritunl Wireguard UDP connections (default is `15403`)
- **additional_security_group:** Additional security (created outside of module) group(s)
- **iam_instance_profile:** Name of iam_instance_profile to assign to EC2 instance (will be created if not supplied)
- **tags:** A map of tags to add to all resources
- **whitelist_ip:** Whitelist this IP for initial ssh connection
- **platform:** Choose platform type: `amd64` (default) or `arm64`; arm64 will require you to indicate an additional `custom_ami_id` variable
- **custom_ami_id:** custom AMI for ARM platform: should be Oracle 8.8 (see notes below)

## Outputs

- **pritunl_private_ip:** Private IP address of the instance
- **pritunl_public_ip:** EIP of the VPN box
- **pritunl_dns_alias:** Route53 DNS record created for Pritunl instance
- **aws_instance_id:** EC2 instance ID
- **main_security_group_id:** Main security group ID
- **aws_ami_id:** AMI ID of amd64 Oracle image

### ARM64 Notes

Module supports custom compilation of Pritunl on ARM64 (using `provision_arm64.sh` script).
However, for that it will need a compatible AMI which should be based on Oracle Linux 8.
I've used the following article to prepare such an image: [Oracle Linux on AWS Graviton2/3](https://www.linkedin.com/pulse/oracle-linux-aws-graviton23-orlando-andico)

Basically you would need to:

- Boot a [Rocky Linux 8 ARM64 AMI](https://aws.amazon.com/marketplace/pp/prodview-uzg6o44ep3ugw) from the AWS Marketplace
- SSH into the instance using the private key, as per standard EC2 practice, with the user being "rocky"
- Obtain the `centos2ol.sh` script from the Oracle Github page page via the command:
  
```bash
curl -O https://raw.githubusercontent.com/oracle/centos2ol/main/centos2ol.sh
```

- Once you've downloaded the script, run it using the command:
  
```bash
sudo bash centos2ol.sh
```

- Wait for the process to complete before rebooting with `/sbin/reboot`
- Once the instance is up and running, SSH back in and validate that the upgrade was successful by executing the command:

```bash
cat /etc/oracle-release
```

You can also check the instance type using the command:

```bash
curl http://169.254.169.254/latest/meta-data/instance-type
```

With these steps, you'll now have Oracle Linux running on your AWS Graviton processor.

Make sure to create AMI out of the instance you've just configured and supply the AMI ID to the module for further Pritunl installation.

Pritunl version: 1.32.3571.58

Python version: 3.9.16

Golang version: 1.20.5

MongoDB: 6.0

### Module Usage

Standard example for amd64 platform:

```bash
provider "aws" {
  region  = "us-east-2"
}

module "pritunl" {
  source = "slitsevych/pritunl/aws"

  aws_key_name         = "my_ssh_key"
  vpc_id               = module.vpc.vpc_id
  public_subnet_id     = element(module.vpc.public_subnets, 0)
  instance_type        = "t3a.small"
  resource_name_prefix = "pritunl"
  domain_name          = "example.com"
  designated_ip        = "1.2.3.4"
}
```

Example for arm64 platform:

```bash
provider "aws" {
  region  = "us-east-2"
}

module "pritunl" {
  source = "slitsevych/pritunl/aws"

  platform             = "arm64"
  aws_key_name         = "my_ssh_key"
  vpc_id               = module.vpc.vpc_id
  public_subnet_id     = element(module.vpc.public_subnets, 0)
  instance_type        = "t4g.small"
  custom_ami_id        = "ami-0123456789ab" # provide your AMI ID (see ARM64 Notes)
  resource_name_prefix = "pritunl-arm"
  subdomain_prefix     = "pritunl-arm"
  domain_name          = "example.com"
  designated_ip        = "1.2.3.4"
  iam_instance_profile = "ec2-ssm-role"  # example of providing existing IAM instance profile
}
```

Please note that it can take few minutes (ideally 10-15 minutes) for provisioner to complete after terraform completes its process.
Once completed, you should ssh to the server and run the following commands:

```bash
sudo pritunl setup-key
```

Once you get the key, open the Pritunl app in browser at its domain URL or IP and use the key to setup DB.
After that use the following command to obtain default credentials:

```bash
sudo pritunl default-password
```

Once done, you can proceed with configuring the server.
