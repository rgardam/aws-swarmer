### Basic config
variable "name" {
  description = "the name of the deployment. This is used to distinguish resources"
}

variable "ssh_public_keystrings" {
  type = "list"
  description = "public ssh keys for docker user"
  default = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUFWdnTi8nrmkH2AAgJ26Mw4iJgLGuwYg6FDkujZHccv2B48hXnVMugh+iFJbPgg9ZxtizxCvsHL2RgpGRk0SzNfDGhEcKZBPCmmilid/wE7p2CKzwy8MwlxV9YO7HlvEkJaDa3GTbDl5/RLpKUyZZCK48FVlMYYsWv/SXCF0VwYLHQA3VnhgEhFqZcBOoHHSzOgYh6fTA9C5V7WpY7Wi76xLClZ6i8C7Qf1Aoh5k2iPdOFapy8lQ8n6mh7GpMb5t1RWUAT1pJopeBY5zOqrmfqhRgWYhZ8Dg9RbEbb84OL9Wa0qPR9vGIQHKXfTwTrDoUNga6QG+eAO2ybQJXYKth robertgardam@ni-bln-04512.local", "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/zwes2ZoXdBn304IwueGP0DzJH+8eHHeU1ff6kuDxT4ImK5JVWGdQj/BaXx77HYloC2ORpx7UXyguf82FsNQPQ0LcalNbPLWT74m9HAgG91gs/7uVhmG1Lgt1P5PUQ0vt+LGVxX4ItixzJgl64ItsVlvhhJ4r1b0hU/ELPAXzB9OMMBliJM7fvpgC+i6dJu4jh8YwIIzbwb3+vNzbqx5rh/K0E9KhjM43GMD6OzHh0m/B5zneWM72SUN3GGzNlkaugZROHMlhpm38Q7Fy5xlYdLx0Rxo+mJdAlmffcsCXm+hnZPDSC0BBNOcem6T/9wFQ9LrRrsgFkM1TrAplgKeT chris@SWS-QA-MacMini-3.local", "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC100a7N4B3oSiH+EnQBPvE4xDWJsFYWEmlssQU2+4AFLUhK7cJZAHoCpjDrLqdle7W40B30caS8ZosWZlu/is2SGyixJyeEYMJdT+7yZ/GXt70W7qqmuey5nvM7dhxePFwb/c0ZFZcCHSdvdyGB4j3A5fLAt70gMk7HnfdoU9h1nnzlruIFdHR92QjFeIKrhEM/+iPeAq0OmEiGuZr8nPKBIUrFIDTULQWIHbHYorIUmPqiDLlf5XJH1oIVNbExOfNGN2hjb0ewBySyiFgoxQ5vjldAdToNTlUeMk9PnA5bvxfi/L93UtznqqIGzv7RApABwl6uaI3joFj7asTIYIJ francois.rose@native-instruments.de", "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+a9NzbAkX2kSFITk0k/rUlVAWsqNldmNDh/RJ/hEW0No6re6z1jUr6KQuhOB7k1fKgRbzyra7DfSdWBB8SML1lvIMnDEXrf/SthdEMLpovrQVzIdK7oTmlMc5labj9w3W1ps7inpEuqDhM9Wab04ne+W89ZebSIXj3WDThlpG1GR36Rcio4sVTYAZNZosTOcaPaaOrD8/ak8BehisyAqAUvWD0OIAQiqwzVrVuSXYmH4sJzMwx2eMPbkt8yK+Tw8xNwoK6kkYfGzEjCKaj7TkIrSMwe0kwUHjtA5qdITQTeqwpLysIjFYZ6eViZmU7Vr9QWcOqV70F+sGA0TjHK6z martinho.fernandes@ni-bln-05929.local"]
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

variable "enable_s3_endpoint" {
  description = "whether we should enable the s3 endpoint in the vpc"
  default = true
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

variable "additional_manager_count" {
  description = "the number of additional manager instances to launch"
  default = 1
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