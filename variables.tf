variable "ssh_public_keystring" {
  description = "public ssh key for docker user"
}

variable "region" {
  description = "aws region"
  default     = "eu-west-1"
}
