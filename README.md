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

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.pritunl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.ssm_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ec2_ssm_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.pritunl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_route53_record.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.vpn_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.pritunl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.oracle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.private_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.public_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group"></a> [additional\_security\_group](#input\_additional\_security\_group) | Additional security (created outside of module) group(s) | `list(any)` | `[]` | no |
| <a name="input_aws_key_name"></a> [aws\_key\_name](#input\_aws\_key\_name) | SSH keypair name for the VPN instance | `any` | n/a | yes |
| <a name="input_custom_ami_id"></a> [custom\_ami\_id](#input\_custom\_ami\_id) | custom AMI for ARM platform: should be Oracle 8.8 | `string` | `""` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name to lookup for A record | `any` | n/a | yes |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | Name of iam\_instance\_profile to assign to EC2 instance | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type for VPN Box | `string` | `"t3a.small"` | no |
| <a name="input_internal_cidrs"></a> [internal\_cidrs](#input\_internal\_cidrs) | [List] IP CIDRs to whitelist in the pritunl's security group | `list(string)` | `[]` | no |
| <a name="input_ovpn_udp_port"></a> [ovpn\_udp\_port](#input\_ovpn\_udp\_port) | port for pritunl OpenVPN UDP between 10000 and 19999 | `number` | `13403` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Platform: amd64 or arm64 | `string` | `"amd64"` | no |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | One of the public subnet id for the VPN instance | `string` | n/a | yes |
| <a name="input_resource_name_prefix"></a> [resource\_name\_prefix](#input\_resource\_name\_prefix) | All the resources will be prefixed with the value of this variable | `string` | `"vpn"` | no |
| <a name="input_subdomain_prefix"></a> [subdomain\_prefix](#input\_subdomain\_prefix) | Prefix for route 53 subdomain | `string` | `"vpn"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(any)` | `{}` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | ec2 volume size | `number` | `30` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Which VPC VPN server will be created in | `string` | n/a | yes |
| <a name="input_whitelist_ip"></a> [whitelist\_ip](#input\_whitelist\_ip) | Whitelist of IP for initial ssh connection | `string` | `""` | no |
| <a name="input_wireguard_udp_port"></a> [wireguard\_udp\_port](#input\_wireguard\_udp\_port) | port for pritunl OpenVPN UDP between 10000 and 19999 | `number` | `15403` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_ami_id"></a> [aws\_ami\_id](#output\_aws\_ami\_id) | n/a |
| <a name="output_aws_instance_id"></a> [aws\_instance\_id](#output\_aws\_instance\_id) | n/a |
| <a name="output_main_security_group_id"></a> [main\_security\_group\_id](#output\_main\_security\_group\_id) | n/a |
| <a name="output_pritunl_dns_alias"></a> [pritunl\_dns\_alias](#output\_pritunl\_dns\_alias) | n/a |
| <a name="output_pritunl_private_ip"></a> [pritunl\_private\_ip](#output\_pritunl\_private\_ip) | n/a |
| <a name="output_pritunl_public_ip"></a> [pritunl\_public\_ip](#output\_pritunl\_public\_ip) | n/a |
<!-- END_TF_DOCS -->