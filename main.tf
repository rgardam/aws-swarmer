

provider "aws" {
  region = "${var.region}"
}

### Data Gatherers ###
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

data "aws_caller_identity" "current" {}

### Random id for secret uniqueness ###
resource "random_id" "key" {
  keepers = {
    # Generate a new id each time we have a new vpc
    vpc_id = "${module.vpc.vpc_id}"
  }

  byte_length = 8
}

### VPC Setup ###
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "swarm"

  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

### Security Groups ### 
resource "aws_security_group" "swarm" {
  name        = "swarm"
  description = "Security group for swarm cluster instances"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
      from_port   = 2375
      to_port     = 2377
      protocol    = "tcp"
      self = true
  }

  ingress {
      from_port   = 7946
      to_port     = 7946
      protocol    = "tcp"
      self = true
  }

  ingress {
      from_port   = 7946
      to_port     = 7946
      protocol    = "udp"
      self = true
  }

  ingress {
      from_port   = 4789
      to_port     = 4789
      protocol    = "tcp"
      self = true
  }

  ingress {
      from_port   = 4789
      to_port     = 4789
      protocol    = "udp"
      self = true
  }

  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [
        "77.180.171.202/32"
      ]
  }

  ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [
        "77.180.171.202/32"
      ]
  }

  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [
        "77.180.171.202/32"
      ]
  }

  egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
  }

  tags {
    Name = "swarm"
  }
}

### KMS Setup ###
resource "aws_kms_key" "swarm_key" {
  description             = "KMS key for whole environment secrets"
}

resource "aws_kms_alias" "swarm_key_alias" {
  name          = "alias/${random_id.key.hex}"
  target_key_id = "${aws_kms_key.swarm_key.key_id}"
}

output "swarm_kms_key_id"   { value = "${aws_kms_key.swarm_key.id}" }


### Template fillers ###
data "template_file" "cloud_init_bootstrap" {
  template   = "${file("${path.module}/templates/cloud-init-bootstrap.yml.tmp")}"

  vars {
    ssh_public_keystring = "${var.ssh_public_keystring}"
    random_id = "${random_id.key.hex}"
    region = "${var.region}"
  } 
}
data "template_file" "cloud_init_manager" {
  template   = "${file("${path.module}/templates/cloud-init-joiner.yml.tmp")}"

  vars {
    ssh_public_keystring = "${var.ssh_public_keystring}"
    random_id = "${random_id.key.hex}"
    region = "${var.region}"
    manager_ip = "${aws_instance.bootstrap_manager.private_ip}"
    type = "manager"
  } 
}

data "template_file" "cloud_init_worker" {
  template   = "${file("${path.module}/templates/cloud-init-joiner.yml.tmp")}"

  vars {
    ssh_public_keystring = "${var.ssh_public_keystring}"
    random_id = "${random_id.key.hex}"
    region = "${var.region}"
    manager_ip = "${aws_instance.bootstrap_manager.private_ip}"
    type = "worker"
  } 
}

data "template_file" "instance_profile" {
  template = "${file("${path.module}/templates/instance_policy.json.tmp")}"

  vars {
    region         = "${var.region}"
    account_id     = "${data.aws_caller_identity.current.account_id}"
    kms_key_id     = "${aws_kms_key.swarm_key.id}"
    random_id      = "${random_id.key.hex}"
  }
}

### IAM Instance Policy ###


resource "aws_iam_role" "swarm" {
  name = "TF_swarm_instance_profile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "swarm" {
  name  = "TF-Swarm-instance_profile"
  role = "${aws_iam_role.swarm.name}"
}

resource "aws_iam_role_policy" "swarm" {
  name   = "TF_swarm_instance_profile"
  role   = "${aws_iam_role.swarm.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

### Swarm Manager Bootstrap Instance ###
resource "aws_instance" "bootstrap_manager" {
  count         = "1"
  ami           = "${data.aws_ami.amazon_linux.id}"
  instance_type = "t2.micro"
  subnet_id     = "${element(module.vpc.public_subnets, count.index)}"
  user_data                   = "${data.template_file.cloud_init_bootstrap.rendered}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile  = "${aws_iam_instance_profile.swarm.name}"
}

### Swarm Manager Manager Instances ###
resource "aws_instance" "additional_managers" {
  count         = "1"
  ami           = "${data.aws_ami.amazon_linux.id}"
  instance_type = "t2.micro"
  subnet_id     = "${element(module.vpc.public_subnets, count.index)}"
  user_data                   = "${data.template_file.cloud_init_manager.rendered}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile  = "${aws_iam_instance_profile.swarm.name}"
}

### Swarm Manager Manager Instances ###
resource "aws_instance" "workers" {
  count         = "1"
  ami           = "${data.aws_ami.amazon_linux.id}"
  instance_type = "t2.micro"
  subnet_id     = "${element(module.vpc.public_subnets, count.index)}"
  user_data                   = "${data.template_file.cloud_init_worker.rendered}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile  = "${aws_iam_instance_profile.swarm.name}"
}



### Swarm Manager ASG ### 
# module "asg" {
#   source = "terraform-aws-modules/autoscaling/aws"

#   # Launch configuration
#   lc_name = "example-lc"

#   image_id        = "ami-ebd02392"
#   instance_type   = "t2.micro"
#   security_groups = ["sg-12345678"]

#   ebs_block_device = [
#     {
#       device_name           = "/dev/xvdz"
#       volume_type           = "gp2"
#       volume_size           = "50"
#       delete_on_termination = true
#     },
#   ]

#   root_block_device = [
#     {
#       volume_size = "50"
#       volume_type = "gp2"
#     },
#   ]

  # Auto scaling group
#   asg_name                  = "example-asg"
#   vpc_zone_identifier       = ["subnet-1235678", "subnet-87654321"]
#   health_check_type         = "EC2"
#   min_size                  = 0
#   max_size                  = 1
#   desired_capacity          = 1
#   wait_for_capacity_timeout = 0

#   tags = [
#     {
#       key                 = "Environment"
#       value               = "dev"
#       propagate_at_launch = true
#     },
#     {
#       key                 = "Project"
#       value               = "megasecret"
#       propagate_at_launch = true
#     },
#   ]
# }


### Swarm Worker ASG ###