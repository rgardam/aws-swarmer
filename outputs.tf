output "sg_swarm" {
  value = "${aws_security_group.swarm.id}"
} 

output "bootstrapped_instance_dns" {
  value = "${aws_instance.bootstrap_manager.public_dns}"
}
 