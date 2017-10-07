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

  cidr = "${var.vpc_cidr_block}"

  azs            = ["${var.vpc_azs}"]
  public_subnets = ["${var.public_subnets}"]
  private_subnets = ["${var.private_subnets}"]

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_nat_gateway = true
  single_nat_gateway = true
}

### Security Groups ### 
resource "aws_security_group" "swarm" {
  name        = "swarm"
  description = "Security group for swarm cluster instances"
  vpc_id      = "${module.vpc.vpc_id}"

  # allow all internal VPC traffic
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["${var.public_access_addresses}"]
  }

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"

    cidr_blocks = ["${var.public_access_addresses}"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = ["${var.public_access_addresses}"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["${var.public_access_addresses}"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags {
    Name = "swarm"
  }
}

### KMS Setup ###
resource "aws_kms_key" "swarm_key" {
  description = "KMS key for whole environment secrets"
}

resource "aws_kms_alias" "swarm_key_alias" {
  name          = "alias/${random_id.key.hex}"
  target_key_id = "${aws_kms_key.swarm_key.key_id}"
}

### Template fillers ###
data "template_file" "cloud_init_bootstrap" {
  template = "${file("${path.module}/templates/cloud-init-bootstrap.yml.tmp")}"

  vars {
    ssh_public_keystring = "${var.ssh_public_keystring}"
    random_id            = "${random_id.key.hex}"
    region               = "${var.region}"
  }
}

data "template_file" "cloud_init_manager" {
  template = "${file("${path.module}/templates/cloud-init-joiner.yml.tmp")}"

  vars {
    ssh_public_keystring = "${var.ssh_public_keystring}"
    random_id            = "${random_id.key.hex}"
    region               = "${var.region}"
    manager_ip           = "${aws_instance.bootstrap_manager.private_ip}"
    type                 = "manager"
  }
}

data "template_file" "cloud_init_worker" {
  template = "${file("${path.module}/templates/cloud-init-joiner.yml.tmp")}"

  vars {
    ssh_public_keystring = "${var.ssh_public_keystring}"
    random_id            = "${random_id.key.hex}"
    region               = "${var.region}"
    manager_ip           = "${aws_instance.bootstrap_manager.private_ip}"
    type                 = "worker"
  }
}

data "template_file" "instance_profile" {
  template = "${file("${path.module}/templates/instance_policy.json.tmp")}"

  vars {
    region     = "${var.region}"
    account_id = "${data.aws_caller_identity.current.account_id}"
    kms_key_id = "${aws_kms_key.swarm_key.id}"
    random_id  = "${random_id.key.hex}"
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
  name = "TF-Swarm-instance_profile"
  role = "${aws_iam_role.swarm.name}"
}

resource "aws_iam_role_policy" "swarm" {
  name   = "TF_swarm_instance_profile"
  role   = "${aws_iam_role.swarm.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

### Swarm Manager Bootstrap Instance ###
resource "aws_instance" "bootstrap_manager" {
  count                       = "1"
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "${var.manager_instance_size}"
  subnet_id                   = "${element(module.vpc.public_subnets, count.index)}"
  user_data                   = "${data.template_file.cloud_init_bootstrap.rendered}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.name}"
}

### Swarm Manager Manager Instances ###
resource "aws_instance" "additional_managers" {
  count                       = "1"
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "${var.manager_instance_size}"
  subnet_id                   = "${element(module.vpc.private_subnets, count.index)}"
  user_data                   = "${data.template_file.cloud_init_manager.rendered}"
  associate_public_ip_address = false
  vpc_security_group_ids      = ["${aws_security_group.swarm.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.swarm.name}"
}

### Launch configuration and autoscaling group for swarm worker
module "swarm_worker_asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  lc_name = "swarm-worker-lc"

  image_id        = "${data.aws_ami.amazon_linux.id}"
  instance_type   = "${var.worker_instance_size}"
  security_groups = ["${aws_security_group.swarm.id}"]
  load_balancers  = ["${module.elb.this_elb_id}"]
  user_data = "${data.template_file.cloud_init_worker.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.swarm.name}"
  root_block_device = [
    {
      volume_size = "20"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "swarm-worker-asg"
  vpc_zone_identifier       = ["${module.vpc.private_subnets}"]
  health_check_type         = "EC2"
  min_size                  = "${var.worker_min_asg_size}"
  max_size                  = "${var.worker_max_asg_size}"
  desired_capacity          = "${var.worker_desired_asg_size}"
  wait_for_capacity_timeout = 0
}

### Swarm Worker ELB ###
module "elb" {
  source = "terraform-aws-modules/elb/aws"

  name = "swarm-elb"

  subnets         = ["${module.vpc.public_subnets}"]
  security_groups = ["${aws_security_group.swarm.id}"]
  internal        = false

  listener = [
    {
      instance_port     = "8080"
      instance_protocol = "TCP"
      lb_port           = "80"
      lb_protocol       = "TCP"
    },
  ]

  health_check = [
    {
      target              = "TCP:7946"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]
}