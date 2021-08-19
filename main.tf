
provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}


locals {
  name        = "qualys"
  environment = "dev"
  ec2_resources_name = "${local.name}-${local.environment}"
}
data "aws_availability_zones" "available" {
  state = "available"
}
########################################################################
##VPC
########################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name

  cidr = "10.12.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1],data.aws_availability_zones.available.names[2]]
  private_subnets = ["10.12.0.0/23", "10.12.2.0/23","10.12.4.0/23"]
  public_subnets  = ["10.12.6.0/23", "10.12.8.0/23", "10.12.10.0/23"]

  enable_nat_gateway = true 
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Environment = local.environment
    Name        = local.name
  }
}

resource "aws_security_group" "my_qualys_security_group" {
  vpc_id       = module.vpc.vpc_id
  name         = "terraform_ecs_security_group"
  description  = "terraform_ecs_security_group"
}

resource "aws_security_group_rule" "egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_qualys_security_group.id
}
#data "aws_ami" "ubuntu" {
#  most_recent = true

#  filter {
#    name   = "name"
#    values = ["qVSA-AWS-2.7.29-4 HVM EBS secure pre-authorized-1b8af947--*"]
#  }

#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }

#  owners = ["099720109477"] # Canonical
#}

resource "aws_instance" "web" {
  
  ami           = "ami-0ceca87b771211982"
  instance_type = "t3.medium"
  #security_groups  = [aws_security_group.my_qualys_security_group.id]
  network_interface {
    network_interface_id = aws_network_interface.ec2_network_interface.id
    device_index         = 0
  }
  user_data              = <<-EOF
              PERSCODE=YOUR_OWN_CODE
              EOF
  #associate_public_ip_address = true
  tags = {
    Name = "qualys"
  }
}

resource "aws_network_interface" "ec2_network_interface" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.12.0.100"]

  tags = {
    Name = "primary_network_interface"
  }
}