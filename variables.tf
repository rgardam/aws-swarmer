### Basic config
variable "ssh_public_keystring" {
  description = "public ssh key for docker user"
}

variable "region" {
  description = "aws region"
  default     = "eu-west-1"
}
### Network configuration ###
variable "public_access_addresses" {
  type = "list"
  description = "The list of ip addresses that can connect to the swarm cluster. This is used for deployments"
}

variable "vpc_cidr_block" {
  description = "the cidr block for the vpc"
  default = "10.0.0.0/16"
}

variable "vpc_azs" {
  type = "list"
  description = "the list of the aws availability zones"
  default = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnets" {
  type = "list"
  description = "the list of public subnets to be deployed. This is where the initial swarm manager will be deployed"
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnets" {
  type = "list"
  description = "the list of private subnets to be deployed. This is where the swarm workers will be deployed"
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

### Instance configuration ###
variable "manager_instance_size" {
  description = "the instance size of the swarm manager"
  default = "t2.micro"
}

variable "worker_instance_size" {
  description = "the instance size of the swarm worker"
  default = "t2.micro"
}

variable "worker_min_asg_size" {
  description = "The minimal number of worker nodes in the swarm cluster"
  default = 0
}

variable "worker_max_asg_size" {
  description = "The maximum number of worker nodes in the swarm cluster"
  default = 1
}

variable "worker_desired_asg_size" {
  description = "The maximum number of worker nodes in the swarm cluster"
  default = 1
}