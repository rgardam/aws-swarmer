
variable "ssh_public_keystring" {
  description = "public ssh key for docker user"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8fSs76zXsQZzoCowT4sUSZOhcoTYmP7sTUcfdtTuR7SfqlmlLAocAwy8TLDkbfoTDb6eGjz6q70bil9VckUqzjjZWMTzKHvUuZ1i4rxn8CsysT8iFX31rCWpuiCRUNlVNm4Beq5u0bzHchmvmKsn4WXCW7KXcHbGoHcTKmWQoDXNj42ZBc6BcsO7PSE1OWTHHazykqBtu0WVvnwNwD069a4vfvEVlB1vuDGJIMlD71Buc+nwL0+2B8/drkPqyGjzd6RvytQPxiuMmMlsZjEas0hNmoIatqxrofnzxFxQY8v8oGNRkxoXRikTP8hOhawaojx0MVIn60i3/09U2oXmj robertg@Roberts-Mac-mini.local"
}


variable "region" {
  description = "aws region"
  default = "eu-west-1"
}